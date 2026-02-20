import { useState, useEffect } from "react";
import API from "../services/api";

export default function NearbyDonors() {

  const [location, setLocation] = useState(null);
  const [radius, setRadius] = useState(5);
  const [organType, setOrganType] = useState("blood");

  const [donors, setDonors] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const [urgency, setUrgency] = useState({});

  // ================= AUTO DETECT LOCATION =================
  useEffect(() => {
    if (!navigator.geolocation) {
      setError("Geolocation not supported by your browser.");
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
      },
      () => {
        setError("Please allow location access to find nearby donors.");
      }
    );
  }, []);

  // ================= SEARCH DONORS =================
  const searchDonors = async () => {
    if (!location) {
      setError("Location not detected yet.");
      return;
    }

    try {
      setLoading(true);
      setError("");

      const res = await API.get("/nearby-donors", {
        params: {
          latitude: location.latitude,
          longitude: location.longitude,
          radius_km: radius,
          organ_type: organType,
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
          organ_type: organType,
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

      {/* SEARCH CONTROLS */}
      <div className="card space-y-4">

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

        <input
          type="number"
          placeholder="Radius (km)"
          value={radius}
          onChange={(e) => setRadius(e.target.value)}
          className="form-input"
        />

        <button onClick={searchDonors} className="primary-btn w-full">
          {loading ? "Searching..." : "Search Donors"}
        </button>

        {location && (
          <p className="text-green-600 text-sm">
            📍 Location detected successfully
          </p>
        )}

        {error && <p className="text-red-500">{error}</p>}
      </div>

      {/* DONOR RESULTS */}
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

                {organType === "blood" && (
                  <p className="text-sm text-gray-500">
                    Blood Group: {donor.blood_group}
                  </p>
                )}

                <p className="text-sm text-gray-500">
                  Distance: {donor.distance_km} km
                </p>

                <p
                  className={`text-sm font-medium ${
                    donor.available
                      ? "text-green-600"
                      : "text-red-600"
                  }`}
                >
                  {donor.available ? "Available" : "Unavailable"}
                </p>
              </div>

              <div className="space-y-3">

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
                  className={`primary-btn ${
                    !donor.available
                      ? "opacity-50 cursor-not-allowed"
                      : ""
                  }`}
                >
                  Send Request
                </button>

              </div>
            </div>

            <div className="mt-3">
              <span className={`${urgencyColors[urgency[donor.id] || "medium"]}`}>
                Selected Urgency: {(urgency[donor.id] || "medium").toUpperCase()}
              </span>
            </div>

          </div>
        ))}

      </div>
    </div>
  );
}
