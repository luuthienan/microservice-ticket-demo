# Ticket Marketplace

Users sell tickets and buy them through orders that are paid for and expire if left unpaid. Each service owns its own data and learns about the others through events.

## Language

**Copy**:
A service's local stand-in for a record owned by another service, kept current through events. A copy always has the same id as its source record.
_Avoid_: Replica, snapshot, mirror

**Version**:
A counter on a record that a Copy follows. A Copy accepts an update only when it is exactly one Version ahead of itself.
_Avoid_: Revision, sequence number

**Reservation**:
A ticket being held by an order, so nobody else can order it. It lasts until that order is cancelled or expires.
_Avoid_: Lock, hold
