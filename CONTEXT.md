# Ticket Marketplace

Users sell tickets and buy them through orders that are paid for and expire if left unpaid. Each service owns its own data and learns about the others through events.

## Language

**Seller**:
The user who listed a ticket for sale. A ticket belongs to its seller, who is the only one who can edit it. The "My Tickets" page lists a seller's tickets in every status.
_Avoid_: Owner, vendor

**Buyer**:
The user who places an order for a ticket. A buyer sees their orders on the "My Orders" page. The tickets service does not know who the buyer is; only the orders service does.
_Avoid_: Customer, purchaser

**Copy**:
A service's local stand-in for a record owned by another service, kept current through events. A copy always has the same id as its source record.
_Avoid_: Replica, snapshot, mirror

**Version**:
A counter on a record that a Copy follows. A Copy applies an update only when it is exactly one Version ahead of itself. An update that is not ahead is already applied and is ignored; one that is more than one ahead means an update is missing and is not applied. An order records the Version of the ticket Copy it was placed from, and the ticket is reserved for it only if the ticket is still at that Version.
_Avoid_: Revision, sequence number

**Order**:
A user's request to buy a ticket. It is Pending until the tickets service confirms the ticket is reserved for it, then awaiting payment until it is paid or cancelled; an order left unpaid past its deadline is cancelled, and one whose reservation is rejected is cancelled. Users see an order as "Pending", "Awaiting payment", "Paid" or "Cancelled", and an expired order is simply "Cancelled".
_Avoid_: Purchase, booking

**Pending**:
An order whose ticket the tickets service has not yet confirmed as reserved for it. It cannot be paid and has no payment deadline. The user may cancel it.
_Avoid_: Processing, created

**Reservation**:
A ticket being held by an order, so nobody else can order it. The tickets service makes it, or rejects it when the ticket was edited since the order was placed or is no longer Available. It lasts until that order is cancelled or expires. While it lasts, the ticket's status is Reserved.
_Avoid_: Lock, hold

**Ticket status**:
Where a ticket stands in its life: Available, Reserved, Sold or Cancelled. The tickets service owns it; other services follow it through their Copy.
_Avoid_: State, Purchased, Created

**Available**:
A ticket nobody holds, which can be ordered and edited by its seller.

**Sold**:
A ticket whose order was paid for. It stays with that order and can no longer be ordered or edited.

**Cancelled** (ticket):
A ticket its seller withdrew from sale. It can no longer be ordered or edited. Not the same as a cancelled Order, which only frees the ticket to be ordered again.

**Event**:
A fact a service announces for other services to act on, such as a record being created or an order being cancelled. Copies follow the Events about their source record.
_Avoid_: Message, notification

**Subject**:
The name an Event is published under, such as `ticket:updated`. A service listens for the Subjects it cares about.
_Avoid_: Topic, channel, stream

**Listener**:
A service's handler for one Subject's Events.
_Avoid_: Subscriber, handler
