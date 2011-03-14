---
layout: post
title: Diving into the Linux Networking Stack, Part I
keywords: linux,networking,receive,packet processing,network,driver
description: The first post in a series that describes the inner workings of the modern Linux networking stack.  This post looks into the low-level driver that connects the hardware to the kernel.
---
*This is the first part of a (planned) multi-part series on receiving a
network packet on a modern Linux kernel.*

Have you ever wondered what happens when your Linux machine gets a packet
from the network?  I have, but most of the information I've seen is
concerned with the [2.4.x
kernel](http://gicl.cs.drexel.edu/people/sevy/network/Linux_network_stack_walkthrough.html).
For my own sake, I decided to take a walk through the Linux networking
stack (using Linux kernel 2.6.37) and thought someone else might be
interested in a little breakdown as well.

### Starting at the Driver ###

I've decided to take a bottom up approach and begin with software that
interacts with the physical network card, the driver.

In general network drivers follow a fairly typical route in processing: the
kernel boots up, initializes data structures, sets up some interrupt
routines, and tells the network card where to put packets when they are
received.  When a packet is actually received, the card signals the kernel
causing it to do some processing and then cleans up some resources.  I'll
talk about the fairly generic routines that network devices share in common
and then move to a concrete example with the `igb` driver.

### A General View of Network Drivers ###

Network drivers are far from the simplest drivers in the kernel.  They push
the speed boundaries of modern multi-core processors.  Almost every new
system comes with a 1 Gigabit per second (Gbps) network card.  Taking into
account that the smallest Ethernet frame size is 64 bytes (plus 8 bytes for
synchronization and a 12 byte inter-frame gap), a 1 Gbps network card should
(by specification) be able to handle:

->![\frac{1 Gbps}{672 bits/frame}=1.488 Million frames per
second](/static/img/2011-03-framerate.png)<-

This leaves us with a processing time of about 672 nanoseconds per frame.
A 2 Gigahertz processor can execute about 1,400 cycles in that time
and a single instruction can take multiple cycles.

Is a modern operating system able to keep up with that rate?  The
simple answer is: "no."  The standard Linux kernel can't keep that
pace for an extended period of time it relies on buffering to handle short
bursts of traffic beyond what it can handle.  It still does its best to get
as many packets as possible using modern network card resources and the
multi-core processors available on the machine.

#### A Quick Refresher on Driver Basics ####

During the boot process the kernel discovers the network card and sets up
its data structures.  These data structures include multiple queues for
receiving packets while the kernel trying to process them.  Each receive
queue is independent from the rest so a processor core can work through its
backlog safely.  To prevent wasteful context switching, interrupts are
disabled while a core works through the packet backlog.  The network card
also writes packets directly to memory so no processor resources are used
to move the packet from one place to another.  

How does this all happen so quickly?  It all depends on some careful
coordination between the kernel and the hardware.  Since every piece of
hardware is different the kernel creates a standard interface between
itself (or the user) and the underlying hardware through a "driver."  The
driver provides the abstract kernel functions by implementing them for the
actual hardware.  The driver uses whatever tricks available to fufill a
request.  Network drivers typically give the hardware a region of memory,
that describes separate memory locations it can write packets to, and
carefully allocates/re-allocates resources as needed.

->![Hardware connects to descriptor rings which connect to memory.  Buffer
rings connect to same memory for
software.](/static/img/2011-03-rings.png)<-

In the figure above, you can see the main components involved in the low
level packet reception: main memory, the network card, and the Linux
kernel.

On the left side, the network card holds a descriptor ring.  An entry in
the descriptor ring points to a location in main memory (which was set up
to be a socket buffer) where it will write the packet.  Entries can also
contain information about the packet or the state of the network card
during reception.

On the right side, the Linux kernel maintains a pool of socket buffers.
The pool concept works well here because the network card needs quick
access to socket buffers, but once used a socket buffer can remain active
for a while so the network card can go back to the pool and grab a new one.
There can also be a simple wrapper between the socket buffers and the
descriptor ring to decrease overhead when moving around the network stack.

Finally, the only real direct communication from the network card to the
kernel happens by way of an interrupt.  Once the network card finishes
receiving a packet it signals the kernel, by way of an interrupt, that it
has processing to do.

### A Concrete Example in `igb` ###

I'm going to work through the Intel Gigabit Ethernet (`drivers/net/igb/`)
driver.  All functions that I'll discuss here are in `igb_main.c`, unless
otherwise noted.  The other files in that directory are very hardware
specific functions that lets the software communicate with the hardware,
the implementation of these is usually just a matter of reading the
hardware specification and writing software that follows the specification.

#### Initialization ####

Typically during the boot process the driver is loaded into the kernel as a
kernel module.  When the module is registered with the kernel it executes a
callback function called `igb_init_module`.  This function registers the
driver with the PCI bus and provides another callback which is executed
once the PCI bus is configured.  Once the PCI bus is ready, we end up at
the `igb_probe` function.

In `igb_probe` the driver actually enables the device on the PCI bus, gets
memory for PCI device input/output, sets device specific callback functions
(like open and close), calls `igb_sw_init` (which sets some software state
and prepares the interrupt system), configures some hardware details, and
ensures the device in a known state.  Each step is important, but
there isn't anything particular to networking devices because this is
generally what *any* PCI device has to do before it is ready.  The real
networking "meat" happens when the device is opened through the `igb_open`
callback that was registered in this stage.

#### Opening the Device ####

When the system actually brings the device up, it calls the `open` function
which n this case is `igb_open`.  This is where the heavy lifting starts
happening.  All the resources needed to send and receive packets are
allocated and the interrupt handler is set up so Linux knows what to do
when a packet is received.  Since I'm more interested in packet reception
than transmission, I'll focus on those parts.

##### Allocating Resources #####

First, we allocate the transmit resources (`igb_setup_all_tx_resources`)
then the receive resources (`igb_setup_all_rx_resources`).  Modern network
are able to use multiple queues (`rx_rings`)---called "Receive Side
Scaling" (RSS) on Intel cards---allowing them to distribute the load
amongst processors.  Thus, the process of setting up all the receive
resources will allocate the resources for each queue.

The resources in this case is a wrapper buffer (`struct igb_buffer` in
`drivers/net/igb/igb.h`), which acts as a software link between the
hardware specific descriptor ring and the software oriented socket buffer.
At this point, none of the socket buffers have yet been allocated but the
hardware knows about the descriptors which will tell it where to place
packets when they start arriving.

After the wrapper buffers have been allocated and the hardware is given the
descriptor ring we must associate each wrapper buffer with a socket buffer
and update the descriptor to point to the socket buffer location.  This
happens in the `igb_alloc_rx_buffers_adv` function (which is called from
`igb_configure`).  If the wrapper is not associated with a free socket
buffer (`struct sk_buff` in `include/linux/skbuff.h`), it will allocate a
new one and set the hardware descriptor to point to the correct locations.
The socket buffer is mapped between hardware and software via direct memory
access (DMA) so no memory copying must be done as it moves through the
network stack.

Now that the wrapper is associated with both a hardware descriptor and a
software socket buffer we are almost ready to receive packets.

##### Configuring Interrupts #####

Now that all the memory resources are allocated the only major hurdle
remaining is setting up interrupts.  There are two interrupt routines that
the driver must set up: the hardware interrupt routine and the software
interrupt routine.

From the `igb_open` function, the `igb_request_irq` function is called.
Again, I'll make the assumption that modern systems are capable of using
the multiple receive queues and therefore will also take advantage of the
Message Signaled Interrupts (MSI-X) which allows more interrupts than there
are physical pins for interrupts.  With a unique interrupt for each receive
queue, the kernel is able to know exactly what caused the interrupt and a
user can pin interrupts from a specific queue to a specific processor core
to minimize detrimental cache effects.  Combining these fact, each receive
queue on the network device requests its own interrupt number and sets the
hardware interrupt routine to be the `igb_msix_ring` function.

At this point when a packet comes in it'll hit the hardware interrupt, but
once the hardware interrupt is finished there isn't a way for the higher
level software to know about the packet.  Enter the software interrupt
function (softIRQ).  Hardware interrupt handlers are designed to be fast,
once done an associated software interrupt is informed and will execute in
a safer context that won't block other interrupts.  So the next thing that
the `igb_request_irq` function does is register a softIRQ with the New
Application Programming Interface (NAPI) layer via `netif_napi_add` (in
`net/core/dev.c` function which adds a callback to `igb_poll`.  The purpose
of the NAPI layer is to mitigate interrupt overheads ("interrupt storms" or
"receive livelock") under heavy packet load.

After a few more simple tidbits to make sure the hardware and software
state matches, interrupts are enabled and the device is ready to send and
receive packets!

#### Receiving a Packet ####

When a packet first arrives at the network card, the device looks at the
next hardware descriptor and begins writing the packet to memory where the
descriptor tells it to (this will be the location of the socket buffer data
as configured during initialization).  Of course, if all the descriptors
the hardware  knows about have been consumed it drops the packet, citing an
overrun error.  Once the packet has been fully received, the hardware
asserts the interrupt signal and the kernel begins running through the
associated interrupt routine (`igb_msix_ring`).  This function is only four
lines of actual code! However one of those lines is to `napi_schedule` (in
`include/linux/netdevice.h`) which does the important stuff.

A hardware interrupt should be quick so the system isn't held up in
interrupt handling.  `napi_schedule` goes through a series of calls to
`__napi_schedule` and `____napi_schedule` (both in `net/core/dev.c`) that
ends with the receive queue being associated with a specific processor on
the system through a list and then signalling the software interrupt so it
will run the next chance it gets.  With the kernel now aware that a packet
is available for processing on the receive queue the hardware interrupt is
done, the hardware signal is un-asserted, and everything is ready for the
next stage of packet processing.

### Conclusions ###

I have now presented both an abstract and concrete view of lower-level
network processing in a modern Linux kernel.  We've gone from having no
network card enabled, allocated the resources needed to receive packets in
a multi-queue configuration, told the hardware about those resources
through the hardware descriptors, configured the interrupt handlers,
received a packet that was stored in memory, and told the kernel about the
packet for further processing.

Now that the kernel knows a packet is on the receive queue, it will
schedule the softirq handler which will call the `igb_poll` function,
reconfigure the descriptors a little, and start performing higher level
networking functions.  The NAPI will come into play stronger than ever once
the softirq is executed, but I'm going to save that for a future post.
