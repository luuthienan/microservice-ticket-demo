import axios from "axios";
import { useState } from "react";

export default function useRequest({ url, method, body, onSuccess }) {
  const [errors, setErrors] = useState(null);

  // `overrideBody` is merged over `body` for values only known at call time (e.g. a payment token).
  // Only plain objects count: `onClick={doRequest}` passes a click event, which must not leak into the body.
  const doRequest = async (overrideBody) => {
    try {
      setErrors(null);
      const extra = overrideBody?.constructor === Object ? overrideBody : {};
      const response = await axios[method](url, { ...body, ...extra });
      if (onSuccess) {
        onSuccess(response.data);
      }
      return response.data;
    } catch (error) {
      const messages = error.response?.data?.errors?.map(e => e.message) ?? ["Something went wrong"];
      setErrors(
        <div className="alert alert-danger">
          <h4>Oooops...</h4>
          <ul className="my-0">
            {messages.map(message => (
              <li key={message}>{message}</li>
            ))}
          </ul>
        </div>
      );
    }
  }

  return { doRequest, errors };
}
