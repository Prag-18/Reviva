import { useState } from "react";
import API from "../services/api";

function NearbyDonors() {
  const [donors, setDonors] = useState([]);

  const searchDonors = async () => {
    const res = await API.get("/nearby-donors", {
      params: {
        latitude: 28.61,
        longitude: 77.20,
        radius_km: 10
      }
    });

    setDonors(res.data);
  };

  const sendRequest = async (donorId) => {
    try {
      await API.post("/create-request", null, {
        params: {
          donor_id: donorId,
          urgency: "critical"
        }
      });

      alert("Request Sent!");
    } catch {
      alert("Failed to send request");
    }
  };

  return (
    <div>
      <h2>Nearby Donors</h2>
      <button onClick={searchDonors}>Search</button>

      {donors.map(d => (
        <div key={d.id}>
          <h3>{d.name}</h3>
          <p>Blood: {d.blood_group}</p>
          <p>Distance: {d.distance_km} km</p>

          {/* 🔥 STEP 8 BUTTON */}
          <button onClick={() => sendRequest(d.id)}>
            Send Request
          </button>
        </div>
      ))}
    </div>
  );
}

export default NearbyDonors;
