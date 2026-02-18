import { useState } from "react";
import API from "../services/api";

export default function Register() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState("donor");
  const [bloodGroup, setBloodGroup] = useState("");
  const [donationType, setDonationType] = useState("blood");
  const [latitude, setLatitude] = useState("");
  const [longitude, setLongitude] = useState("");

  const handleRegister = async (e) => {
    e.preventDefault();

    try {
      await API.post("/register", null, {
        params: {
          name,
          email,
          password,
          role,
          blood_group: bloodGroup,
          donation_type: donationType,   // ✅ THIS IS WHERE IT GOES
          latitude,
          longitude
        }
      });

      alert("Registered successfully!");
    } catch (err) {
      alert(err.response?.data?.detail || "Registration failed");
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-6">

      <div className="bg-white/90 backdrop-blur-lg shadow-2xl rounded-3xl p-10 w-full max-w-3xl border border-rose-100">

        <h1 className="text-3xl font-bold text-center text-rose-600 mb-8">
          Create Your Account ❤️
        </h1>

        <form
          onSubmit={handleRegister}
          className="grid md:grid-cols-2 gap-6"
        >

          {/* Name */}
          <input
            type="text"
            placeholder="Full Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="form-input"
            required
          />

          {/* Email */}
          <input
            type="email"
            placeholder="Email Address"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="form-input"
            required
          />

          {/* Password */}
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="form-input"
            required
          />

          {/* Role */}
          <select
            value={role}
            onChange={(e) => setRole(e.target.value)}
            className="form-input"
          >
            <option value="donor">Donor</option>
            <option value="seeker">Seeker</option>
          </select>

          {/* Donation Type */}
          <select
            value={donationType}
            onChange={(e) => setDonationType(e.target.value)}
            className="form-input"
          >
            <option value="blood">Blood</option>
            <option value="kidney">Kidney</option>
            <option value="liver">Liver</option>
            <option value="heart">Heart</option>
            <option value="cornea">Cornea</option>
            <option value="bone_marrow">Bone Marrow</option>
          </select>

          {/* Blood Group (Only if blood selected) */}
          {donationType === "blood" && (
            <input
              type="text"
              placeholder="Blood Group (e.g., A+)"
              value={bloodGroup}
              onChange={(e) => setBloodGroup(e.target.value)}
              className="form-input"
              required
            />
          )}

          {/* Latitude */}
          <input
            type="number"
            placeholder="Latitude"
            value={latitude}
            onChange={(e) => setLatitude(e.target.value)}
            className="form-input"
            required
          />

          {/* Longitude */}
          <input
            type="number"
            placeholder="Longitude"
            value={longitude}
            onChange={(e) => setLongitude(e.target.value)}
            className="form-input"
            required
          />

          {/* Submit Button */}
          <div className="md:col-span-2 mt-4">
            <button
              type="submit"
              className="w-full bg-gradient-to-r from-rose-500 to-red-500 hover:from-red-500 hover:to-rose-600 text-white font-semibold py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-300"
            >
              Register Now
            </button>
          </div>

        </form>

      </div>

    </div>
  );

}
