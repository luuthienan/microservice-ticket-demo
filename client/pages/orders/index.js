import Link from "next/link";
import Router from "next/router";

// "Cancelled" also covers orders that expired unpaid: expiry cancels the order.
// A "created" order is Pending: its ticket is not yet confirmed, so it can't be paid.
const describeOrder = (order) => {
  if (order.status === "complete") {
    return { label: "Paid", action: "View" };
  }
  if (order.status === "created") {
    return { label: "Pending", action: "View" };
  }
  if (order.status === "awaiting_payment" && new Date(order.expires_at) > Date.now()) {
    return { label: "Awaiting payment", action: "Pay" };
  }
  return { label: "Cancelled", action: "View" };
};

const OrderIndex = ({ orders }) => {
  const orderList = orders.map(order => {
    const { label, action } = describeOrder(order);

    return (
      <tr key={order.id}>
        <td>{order.ticket.title}</td>
        <td>${order.ticket.price}</td>
        <td>{label}</td>
        <td>
          <Link href={"/orders/[orderId]"} as={`/orders/${order.id}`}>
            {action}
          </Link>
        </td>
      </tr>
    );
  });

  return (
    <div>
      <h1>My Orders</h1>
      {orders.length === 0 ? (
        <p>You have no orders yet.</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Ticket</th>
              <th>Price</th>
              <th>Status</th>
              <th>Link</th>
            </tr>
          </thead>
          <tbody>
            {orderList}
          </tbody>
        </table>
      )}
    </div>
  );
};

OrderIndex.getInitialProps = async (context, client, currentUser) => {
  if (!currentUser) {
    if (context.res) {
      context.res.writeHead(302, { Location: "/auth/signin" });
      context.res.end();
    } else {
      Router.push("/auth/signin");
    }
    return { orders: [] };
  }

  const { data } = await client.get("/api/v1/orders");

  return { orders: data };
};

export default OrderIndex;
