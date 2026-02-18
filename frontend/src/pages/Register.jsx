import { useState } from "react";
import { useNavigate } from "react-router-dom";
import API from "../services/api";

function Register() {
  const [form, setForm] = useState({
    name: "",
    email: "",
    password: "",
    role: "",
    blood_group: "",
    latitude: "",
    longitude: ""
  });

  const navigate = useNavigate();

  const handleRegister = async () => {
    try {
      await API.post("/register", null, {
        params: form   // 🔥 IMPORTANT (backend expects query params)
      });

      alert("User registered successfully!");
      navigate("/");  // Redirect to login after register
    } catch (error) {
      console.error(error);
      alert("Registration failed");
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="card w-[700px]">

        <h1 className="text-3xl font-bold text-center text-rose-600 mb-6">
          Register
        </h1>

        <div className="grid grid-cols-2 gap-4">

          <input
            className="form-input"
            placeholder="Full Name"
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />

          <input
            className="form-input"
            placeholder="Email"
            onChange={(e) => setForm({ ...form, email: e.target.value })}
          />

          <input
            type="password"
            className="form-input"
            placeholder="Password"
            onChange={(e) => setForm({ ...form, password: e.target.value })}
          />

          <select
            className="form-input"
            onChange={(e) => setForm({ ...form, role: e.target.value })}
          >
            <option value="">Select Role</option>
            <option value="donor">Donor</option>
            <option value="seeker">Seeker</option>
          </select>

          <select
            className="form-input"
            onChange={(e) => setForm({ ...form, blood_group: e.target.value })}
          >
            <option value="">Blood Group</option>
            <option>A+</option>
            <option>A-</option>
            <option>B+</option>
            <option>B-</option>
            <option>O+</option>
            <option>O-</option>
            <option>AB+</option>
            <option>AB-</option>
          </select>

          <input
            className="form-input"
            placeholder="Latitude"
            type="number"
            onChange={(e) => setForm({ ...form, latitude: e.target.value })}
          />

          <input
            className="form-input"
            placeholder="Longitude"
            type="number"
            onChange={(e) => setForm({ ...form, longitude: e.target.value })}
          />

        </div>

        <button
          onClick={handleRegister}
          className="primary-btn w-full mt-8"
        >
          Register
        </button>

      </div>
    </div>
  );
}

export default Register;
