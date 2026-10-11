import { useState } from 'react';
import Link from 'next/link';
import Router from 'next/router';
import useRequest from '../../../hooks/use-request';

const EditTicket = ({ ticket, editable }) => {
  const [title, setTitle] = useState(ticket.title);
  const [price, setPrice] = useState(ticket.price);
  const { doRequest, errors } = useRequest({
    url: `/api/v1/tickets/${ticket.id}`,
    method: 'put',
    body: {
      title,
      price
    },
    onSuccess: () => Router.push('/tickets/mine')
  });

  const onSubmit = (e) => {
    e.preventDefault();
    doRequest();
  };

  const onBlur = () => {
    const value = parseFloat(price);
    if (isNaN(value)) {
      return;
    }
    setPrice(value.toFixed(2));
  };

  if (!editable) {
    return (
      <div>
        <h1>Edit Ticket</h1>
        <p>This ticket can't be edited.</p>
        <Link href="/tickets/mine">Back to My Tickets</Link>
      </div>
    );
  }

  return (
    <div>
      <h1>Edit Ticket</h1>
      <form onSubmit={onSubmit}>
        <div className="form-group">
          <label>Title</label>
          <input
            className="form-control"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label>Price</label>
          <input
            className="form-control"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            onBlur={onBlur}
          />
        </div>
        {errors}
        <button className="btn btn-primary">Save</button>
      </form>
    </div>
  );
};

EditTicket.getInitialProps = async (context, client, currentUser) => {
  if (!currentUser) {
    if (context.res) {
      context.res.writeHead(302, { Location: '/auth/signin' });
      context.res.end();
    } else {
      Router.replace('/auth/signin');
    }
    return { ticket: { id: null, title: '', price: '' }, editable: false };
  }

  const { ticketId } = context.query;
  const { data } = await client.get(`/api/v1/tickets/${ticketId}`);

  return {
    ticket: data,
    editable: data.user_id === currentUser.id && data.status === 'available'
  };
};

export default EditTicket;
