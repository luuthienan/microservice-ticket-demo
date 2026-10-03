import { useState } from "react";
import Router from "next/router";
import useRequest from "../../hooks/use-request";

export default function Signin() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const { doRequest, errors } = useRequest({
    url: "/api/v1/users/signin",
    method: "post",
    body: { email, password },
    onSuccess: () => Router.push("/")
  });

  const handleSignin = async (event) => {
    event.preventDefault();
    await doRequest();
  };

  return (
    <form onSubmit={handleSignin}>
      <h1>Sign In</h1>
      <div className="form-group">
        <label htmlFor="email">Email</label>
        <input className="form-control" id="email" value={email} onChange={(e) => setEmail(e.target.value)} />
      </div>
      <div className="form-group">
        <label htmlFor="password">Password</label>
        <input type="password" className="form-control" id="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      </div>
      {errors}
      <button type="submit" className="btn btn-primary">Sign In</button>
    </form>
  );
}
