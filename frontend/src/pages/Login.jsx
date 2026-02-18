import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import API, { setAuthToken } from "../services/api";

function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();

  const handleLogin = async () => {
    try {
      const res = await API.post("/login", null, {
        params: { email, password }
      });

      const token = res.data.access_token;

      localStorage.setItem("token", token);
      setAuthToken(token);

      navigate("/dashboard");
    } catch (err) {
      alert("Invalid email or password");
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="card w-[500px]">

        <h1 className="text-3xl font-bold text-center text-rose-600 mb-6">
          Login
        </h1>

        <div className="space-y-4">
          <input
            className="form-input w-full"
            placeholder="Email"
            onChange={(e) => setEmail(e.target.value)}
          />

          <input
            type="password"
            className="form-input w-full"
            placeholder="Password"
            onChange={(e) => setPassword(e.target.value)}
          />
        </div>

        <button
          onClick={handleLogin}
          className="primary-btn w-full mt-6"
        >
          Login
        </button>

        {/* 👇 Register Link */}
        <p className="text-center text-gray-500 mt-6">
          Don’t have an account?{" "}
          <Link
            to="/register"
            className="text-rose-600 font-semibold hover:underline"
          >
            Register here
          </Link>
        </p>

      </div>
    </div>
  );
}

export default Login;
