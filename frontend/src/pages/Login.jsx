import { useState } from "react";
import { useNavigate } from "react-router-dom";
import API, { setAuthToken } from "../services/api";

function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      // ✅ Backend logic from first code (using params)
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
    <div className="min-h-screen flex items-center justify-center px-6">
      <div className="max-w-6xl w-full grid md:grid-cols-2 gap-16 items-center">

        {/* LEFT SIDE - BRANDING */}
        <div className="text-center md:text-left space-y-6">
          <h1 className="text-5xl font-bold text-rose-600 leading-tight">
            Welcome to <span className="text-red-500">Reviva</span> ❤️
          </h1>

          <p className="text-lg text-gray-600 max-w-md mx-auto md:mx-0">
            Connecting donors and seekers through a secure, real-time
            life-saving network.
          </p>

          <div className="flex justify-center md:justify-start gap-4 mt-4">
            <div className="bg-white shadow-md px-5 py-3 rounded-xl text-sm font-medium">
              🩸 Blood Donation
            </div>

            <div className="bg-white shadow-md px-5 py-3 rounded-xl text-sm font-medium">
              🫀 Organ Donation
            </div>
          </div>
        </div>

        {/* RIGHT SIDE - LOGIN CARD */}
        <div className="bg-white p-10 rounded-3xl shadow-2xl border border-gray-100 w-full max-w-md mx-auto">
          <h2 className="text-2xl font-bold text-center text-rose-600 mb-6">
            Login
          </h2>

          <form onSubmit={handleLogin} className="space-y-5">

            <input
              type="email"
              placeholder="Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="form-input w-full"
              required
            />

            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="form-input w-full"
              required
            />

            <button type="submit" className="primary-btn w-full">
              Login
            </button>

          </form>

          <p className="text-sm text-gray-500 text-center mt-6">
            Don’t have an account?{" "}
            <span
              className="text-rose-600 font-semibold cursor-pointer hover:underline"
              onClick={() => navigate("/register")}
            >
              Register here
            </span>
          </p>

        </div>
      </div>
    </div>
  );
}

export default Login;
