import Link from "next/link";
import Router from "next/router";
import { STATUS_LABELS } from "../../components/ticket-status";
import useRequest from "../../hooks/use-request";

const TicketRow = ({ ticket }) => {
  const { doRequest, errors } = useRequest({
    url: `/api/v1/tickets/${ticket.id}/cancel`,
    method: "post",
    onSuccess: () => Router.replace(Router.asPath),
  });

  const cancel = () => {
    if (window.confirm("Cancel this ticket? This can't be undone.")) {
      doRequest();
    }
  };

  return (
    <tr>
      <td>{ticket.title}</td>
      <td>${ticket.price}</td>
      <td>{STATUS_LABELS[ticket.status] || ticket.status}</td>
      <td>
        <Link href={"/tickets/[ticketId]"} as={`/tickets/${ticket.id}`}>
          View
        </Link>
        {ticket.status === "available" && (
          <button className="btn btn-link text-danger p-0 ms-3" onClick={cancel}>
            Cancel
          </button>
        )}
        {errors}
      </td>
    </tr>
  );
};

const MyTickets = ({ tickets }) => {
  const ticketList = tickets.map(ticket => <TicketRow key={ticket.id} ticket={ticket} />);

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center">
        <h1>My Tickets</h1>
        <Link href="/tickets/new" className="btn btn-primary">
          New Ticket
        </Link>
      </div>
      {tickets.length === 0 ? (
        <p>You have no tickets yet.</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Title</th>
              <th>Price</th>
              <th>Status</th>
              <th>Link</th>
            </tr>
          </thead>
          <tbody>
            {ticketList}
          </tbody>
        </table>
      )}
    </div>
  );
};

MyTickets.getInitialProps = async (context, client, currentUser) => {
  if (!currentUser) {
    if (context.res) {
      context.res.writeHead(302, { Location: "/auth/signin" });
      context.res.end();
    } else {
      Router.push("/auth/signin");
    }
    return { tickets: [] };
  }

  const { data } = await client.get("/api/v1/tickets/mine");

  return { tickets: data };
};

export default MyTickets;
