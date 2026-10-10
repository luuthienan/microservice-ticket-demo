import Route from "next/router";
import useRequest from "../../hooks/use-request";
import { STATUS_LABELS } from "../../components/ticket-status";

const TicketShow = ({ ticket }) => {
  const { doRequest, errors } = useRequest({
    url: "/api/v1/orders",
    method: "post",
    body: {
      ticket_id: ticket.id
    },
    onSuccess: (order) => {
      Route.push("/orders/[orderId]", `/orders/${order.id}`);
    }
  });

  return (
    <div>
      <h1>{ticket.title}</h1>
      <h4>Price: ${ticket.price}</h4>
      <h5>Status: {STATUS_LABELS[ticket.status] || ticket.status}</h5>
      {errors}
      <button
        className="btn btn-primary"
        onClick={doRequest}
        disabled={ticket.status !== "available"}
      >
        Purchase
      </button>
    </div>
  );
};

TicketShow.getInitialProps = async (context, client, currentUser) => {
  const { ticketId } = context.query;
  const { data } = await client.get(`/api/v1/tickets/${ticketId}`);

  return { ticket: data };
};

export default TicketShow;
