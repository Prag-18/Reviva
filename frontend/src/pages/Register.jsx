import { useState } from "react";
import { useNavigate } from "react-router-dom";
import API from "../services/api";

export default function Register() {
  const navigate = useNavigate();
  const [location, setLocation] = useState({
    latitude: null,
    longitude: null,
  });
  const handleLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLocation({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
          });
          alert("Location captured!");
        },
        () => {
          alert("Unable to fetch location");
        }
      );
    }
  };

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    role: "donor",
    donation_type: "blood",
    blood_group: "",
    phone: "",
  });

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleRegister = async (e) => {
    e.preventDefault();

    try {
      await API.post("/register", null, {
        params: {
          name: formData.name,
          email: formData.email,
          password: formData.password,
          role: formData.role,
          donation_type: formData.donation_type,
          blood_group: formData.blood_group,
          phone: formData.phone,
          latitude: location.latitude,       
          longitude: location.longitude,    
        },
      });


      alert("Registration successful!");
      navigate("/");
    } catch (error) {
      alert(error.response?.data?.detail || "Registration failed");
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-6">
      <div className="bg-white p-10 rounded-3xl shadow-2xl w-full max-w-md">

        <h2 className="text-2xl font-bold text-center text-rose-600 mb-6">
          Register
        </h2>

        <form onSubmit={handleRegister} className="space-y-4">

          <input
            type="text"
            name="name"
            placeholder="Full Name"
            className="form-input w-full"
            onChange={handleChange}
            required
          />

          <input
            type="email"
            name="email"
            placeholder="Email"
            className="form-input w-full"
            onChange={handleChange}
            required
          />

          <input
            type="password"
            name="password"
            placeholder="Password"
            className="form-input w-full"
            onChange={handleChange}
            required
          />

          <input
            type="text"
            name="phone"
            placeholder="Phone Number"
            className="form-input w-full"
            onChange={handleChange}
          />

          <select
            name="role"
            className="form-input w-full"
            onChange={handleChange}
          >
            <option value="donor">Donor</option>
            <option value="seeker">Seeker</option>
          </select>

          <select
            name="donation_type"
            className="form-input w-full"
            onChange={handleChange}
          >
            <option value="blood">Blood</option>
            <option value="kidney">Kidney</option>
            <option value="liver">Liver</option>
            <option value="heart">Heart</option>
            <option value="cornea">Cornea</option>
            <option value="bone_marrow">Bone Marrow</option>
          </select>

          <input
            type="text"
            name="blood_group"
            placeholder="Blood Group (if blood donor)"
            className="form-input w-full"
            onChange={handleChange}
          />
          <button
            type="button"
            onClick={handleLocation}
            className="bg-gray-200 px-4 py-2 rounded-lg w-full"
          >
            📍 Use Current Location
          </button>

          <button type="submit" className="primary-btn w-full">
            Register
          </button>

        </form>
      </div>
    </div>
  );
}
