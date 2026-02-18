import { useEffect, useState } from "react";
import API from "../services/api";

export default function Requests({ user }) {

  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchRequests = async () => {
    try {
      const res = await API.get(`/my-requests/${user.id}`);
      setRequests(res.data);
    } catch (err) {
      console.error("Error fetching requests");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchRequests();
    }
  }, [user]);

  const acceptRequest = async (id) => {
    await API.put(`/accept-request/${id}`);
    fetchRequests();
  };

  const rejectRequest = async (id) => {
    await API.put(`/reject-request/${id}`);
    fetchRequests();
  };

  const urgencyColors = {
    low: "text-blue-500",
    medium: "text-yellow-500",
    high: "text-orange-500",
    critical: "text-red-600 font-bold",
  };

  const statusColors = {
    pending: "bg-yellow-100 text-yellow-700",
    accepted: "bg-green-100 text-green-700",
    rejected: "bg-red-100 text-red-700",
  };

  if (loading) return <div className="p-10">Loading...</div>;

  return (
    <div className="p-10 space-y-8">

      <h1 className="text-3xl font-bold text-rose-600">
        {user.role === "donor" ? "Received Requests" : "Sent Requests"}
      </h1>

      {requests.length === 0 && (
        <p className="text-gray-500">No requests yet.</p>
      )}

      {requests.map((req) => (
        <div key={req.id} className="card">

          <div className="flex justify-between items-center">

            <div>
              <h2 className="text-xl font-semibold">
                {user.role === "donor"
                  ? req.seeker_name
                  : req.donor_name}
              </h2>

              <p className="text-gray-600 mt-1">
                Organ: {req.organ_type?.toUpperCase()}
              </p>

              <p className={`mt-2 ${urgencyColors[req.urgency]}`}>
                Urgency: {req.urgency.toUpperCase()}
              </p>
            </div>

            <span
              className={`px-4 py-1 rounded-full text-sm font-semibold ${statusColors[req.status]}`}
            >
              {req.status.toUpperCase()}
            </span>

          </div>

          {user.role === "donor" && req.status === "pending" && (
            <div className="flex gap-4 mt-6">
              <button
                onClick={() => acceptRequest(req.id)}
                className="bg-green-500 text-white px-4 py-2 rounded-xl hover:bg-green-600"
              >
                Accept
              </button>

              <button
                onClick={() => rejectRequest(req.id)}
                className="bg-red-500 text-white px-4 py-2 rounded-xl hover:bg-red-600"
              >
                Reject
              </button>
            </div>
          )}

        </div>
      ))}

    </div>
  );
}
