import { useState } from "react";
import API from "../services/api";

export default function NearbyDonors() {

  const [latitude, setLatitude] = useState("");
  const [longitude, setLongitude] = useState("");
  const [radius, setRadius] = useState(5);

  const [organType, setOrganType] = useState("blood"); // ✅ NEW

  const [donors, setDonors] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const [urgency, setUrgency] = useState({});

  // ================= SEARCH DONORS =================
  const searchDonors = async () => {
    if (!latitude || !longitude) {
      setError("Please enter latitude and longitude.");
      return;
    }

    try {
      setLoading(true);
      setError("");

      const res = await API.get("/nearby-donors", {
        params: {
          latitude,
          longitude,
          radius_km: radius,
          organ_type: organType, // ✅ Send organ type to backend
        },
      });

      setDonors(res.data);
    } catch (err) {
      setError("Error fetching donors.");
    } finally {
      setLoading(false);
    }
  };

  // ================= SEND REQUEST =================
  const sendRequest = async (donorId) => {
    try {
      const selectedUrgency = urgency[donorId] || "medium";

      await API.post("/create-request", null, {
        params: {
          donor_id: donorId,
          urgency: selectedUrgency,
          organ_type: organType, // ✅ Include organ type
        },
      });

      alert("Request sent successfully!");
    } catch (err) {
      alert(err.response?.data?.detail || "Error sending request");
    }
  };

  const urgencyColors = {
    low: "text-blue-500",
    medium: "text-yellow-500",
    high: "text-orange-500",
    critical: "text-red-600 font-bold",
  };

  return (
    <div className="space-y-8">

      <h2 className="text-2xl font-semibold">
        Find Nearby {organType.charAt(0).toUpperCase() + organType.slice(1)} Donors
      </h2>

      {/* Search Controls */}
      <div className="card space-y-4">

        {/* ✅ ORGAN TYPE SELECTOR */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Select Donation Type
          </label>

          <select
            value={organType}
            onChange={(e) => setOrganType(e.target.value)}
            className="form-input w-full"
          >
            <option value="blood">Blood</option>
            <option value="kidney">Kidney</option>
            <option value="liver">Liver</option>
            <option value="cornea">Cornea</option>
            <option value="bone_marrow">Bone Marrow</option>
          </select>
        </div>

        <div className="grid md:grid-cols-3 gap-4">
          <input
            type="number"
            placeholder="Latitude"
            value={latitude}
            onChange={(e) => setLatitude(e.target.value)}
            className="form-input"
          />

          <input
            type="number"
            placeholder="Longitude"
            value={longitude}
            onChange={(e) => setLongitude(e.target.value)}
            className="form-input"
          />

          <input
            type="number"
            placeholder="Radius (km)"
            value={radius}
            onChange={(e) => setRadius(e.target.value)}
            className="form-input"
          />
        </div>

        <button onClick={searchDonors} className="primary-btn w-full">
          {loading ? "Searching..." : "Search Donors"}
        </button>

        {error && <p className="text-red-500">{error}</p>}
      </div>

      {/* Donor Results */}
      <div className="space-y-6">

        {donors.length === 0 && !loading && (
          <p className="text-gray-500">No donors found.</p>
        )}

        {donors.map((donor) => (
          <div key={donor.id} className="card">

            <div className="flex justify-between items-center">

              <div>
                <h3 className="text-lg font-semibold">
                  {donor.name}
                </h3>

                {/* Show blood group only if blood selected */}
                {organType === "blood" && (
                  <p className="text-sm text-gray-500">
                    Blood Group: {donor.blood_group}
                  </p>
                )}

                <p className="text-sm text-gray-500">
                  Distance: {donor.distance_km} km
                </p>

                <p
                  className={`text-sm font-medium ${donor.available
                      ? "text-green-600"
                      : "text-red-600"
                    }`}
                >
                  {donor.available
                    ? "Available"
                    : "Unavailable"}
                </p>
              </div>

              <div className="space-y-3">

                {/* Urgency Selector */}
                <select
                  value={urgency[donor.id] || "medium"}
                  onChange={(e) =>
                    setUrgency({
                      ...urgency,
                      [donor.id]: e.target.value,
                    })
                  }
                  className="form-input"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                  <option value="critical">Critical</option>
                </select>

                <button
                  onClick={() => sendRequest(donor.id)}
                  disabled={!donor.available}
                  className={`primary-btn ${!donor.available
                      ? "opacity-50 cursor-not-allowed"
                      : ""
                    }`}
                >
                  Send Request
                </button>

              </div>
            </div>

            <div className="mt-3">
              <span
                className={`${urgencyColors[
                  urgency[donor.id] || "medium"
                ]}`}
              >
                Selected Urgency:{" "}
                {(urgency[donor.id] || "medium").toUpperCase()}
              </span>
            </div>

          </div>
        ))}

      </div>
    </div>
  );
}
