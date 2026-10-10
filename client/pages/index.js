import Link from "next/link";
import buildClient from "../api/build-client";
import { STATUS_LABELS } from "../components/ticket-status";

const LandingPage = ({ currentUser, tickets }) => {
  const ticketList = tickets.map(ticket => {
    return (
      <tr key={ticket.id}>
        <td>{ticket.title}</td>
        <td>${ticket.price}</td>
        <td>{STATUS_LABELS[ticket.status] || ticket.status}</td>
        <td>
          <Link href={"/tickets/[ticketId]"} as={`/tickets/${ticket.id}`}>
            View
          </Link>
        </td>
      </tr>
    );
  });

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center">
        <h1>Tickets</h1>
        {currentUser && (
          <Link href="/tickets/new" className="btn btn-primary">
            New Ticket
          </Link>
        )}
      </div>
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
    </div>
  )
};

LandingPage.getInitialProps = async (context, client, currentUser) => {
  const { data } = await client.get("/api/v1/tickets");

  return { tickets: data };
};

export default LandingPage;
