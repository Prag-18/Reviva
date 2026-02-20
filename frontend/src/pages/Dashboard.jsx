import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import API from "../services/api";
import NearbyDonors from "./NearbyDonors";

export default function Dashboard() {
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");
  const [timeFilter, setTimeFilter] = useState("all");

  useEffect(() => {
  if (!user) return;

  const ws = new WebSocket(`ws://127.0.0.1:8000/ws/${user.id}`);

  ws.onmessage = (event) => {
    console.log("WebSocket message:", event.data);

    // Refresh requests for ANY update
    fetchRequests(user.id);
  };

  ws.onerror = (err) => {
    console.error("WebSocket error:", err);
  };

  return () => ws.close();
}, [user]);

  // ================= FETCH USER =================
  const fetchUser = async () => {
    try {
      const res = await API.get("/me");
      setUser(res.data);
    } catch (err) {
      console.error("Error fetching user", err);
    }
  };

  // ================= FETCH REQUESTS =================
  const fetchRequests = async (userId) => {
    try {
      const res = await API.get(`/my-requests/${userId}`);
      setRequests(res.data);
    } catch (err) {
      console.error("Error fetching requests", err);
    } finally {
      setLoading(false);
    }
  };

  // ================= TOGGLE AVAILABILITY =================
  const toggleAvailability = async () => {
    try {
      const res = await API.put("/toggle-availability");
      setUser({ ...user, available: res.data.available });
    } catch (err) {
      console.error("Error toggling availability", err);
    }
  };

  // ================= ACCEPT REQUEST =================
  const acceptRequest = async (id) => {
    try {
      await API.put(`/accept-request/${id}`);
      fetchRequests(user.id);
    } catch (err) {
      alert("Error accepting request");
    }
  };

  // ================= REJECT REQUEST =================
  const rejectRequest = async (id) => {
    try {
      await API.put(`/reject-request/${id}`);
      fetchRequests(user.id);
    } catch (err) {
      alert("Error rejecting request");
    }
  };

  // ================= INITIAL LOAD =================
  useEffect(() => {
    fetchUser();
  }, []);

  useEffect(() => {
    if (user) {
      fetchRequests(user.id);
    }
  }, [user]);

  if (loading || !user) {
    return <div className="p-10 text-center">Loading...</div>;
  }
  const now = new Date();

  const timeFilteredRequests = requests.filter((req) => {
    if (timeFilter === "all") return true;

    const createdDate = new Date(req.created_at);

    const diffInDays =
      (now - createdDate) / (1000 * 60 * 60 * 24);

    if (timeFilter === "today") return diffInDays <= 1;
    if (timeFilter === "7days") return diffInDays <= 7;
    if (timeFilter === "30days") return diffInDays <= 30;

    return true;
  });

  // ================= STATS =================
  const total = requests.length;
  const pending = requests.filter((r) => r.status === "pending").length;
  const accepted = requests.filter((r) => r.status === "accepted").length;
  const rejected = requests.filter((r) => r.status === "rejected").length;

  const filteredRequests =
    filter === "all"
      ? requests
      : requests.filter((r) => r.status === filter);

  return (
    <div className="max-w-6xl mx-auto px-6 py-10 space-y-12">

      {/* HERO */}
      <div className="bg-gradient-to-r from-rose-600 via-pink-500 to-red-500 text-white p-10 rounded-3xl shadow-xl">
        <h1 className="text-4xl font-bold">
          Welcome back, {user.name} ❤️
        </h1>

        <button
          onClick={() => navigate("/profile")}
          className="mt-6 bg-white text-rose-600 px-6 py-2 rounded-xl font-semibold shadow hover:shadow-lg"
        >
          Go to Profile
        </button>
      </div>
      <div className="flex flex-wrap gap-3 mb-6">

        {[
          { label: "All Time", value: "all" },
          { label: "Today", value: "today" },
          { label: "Last 7 Days", value: "7days" },
          { label: "Last 30 Days", value: "30days" },
        ].map((option) => (
          <button
            key={option.value}
            onClick={() => setTimeFilter(option.value)}
            className={`px-4 py-2 rounded-full text-sm font-semibold transition ${timeFilter === option.value
                ? "bg-rose-600 text-white"
                : "bg-gray-200 text-gray-700"
              }`}
          >
            {option.label}
          </button>
        ))}

      </div>


      {/* STATS CARDS */}
      <div className="grid md:grid-cols-4 gap-6">

        {/* TOTAL */}
        <div
          onClick={() => setFilter("all")}
          className={`card text-center cursor-pointer transition hover:scale-105 ${filter === "all" ? "ring-2 ring-rose-500" : ""
            }`}
        >
          <p className="text-gray-500">Total</p>
          <h2 className="text-4xl font-bold text-rose-600 mt-2">
            {total}
          </h2>
        </div>

        {/* PENDING */}
        <div
          onClick={() => setFilter("pending")}
          className={`card text-center cursor-pointer transition hover:scale-105 ${filter === "pending" ? "ring-2 ring-yellow-500" : ""
            }`}
        >
          <p className="text-gray-500">Pending</p>
          <h2 className="text-4xl font-bold text-yellow-500 mt-2">
            {pending}
          </h2>
        </div>

        {/* ACCEPTED */}
        <div
          onClick={() => setFilter("accepted")}
          className={`card text-center cursor-pointer transition hover:scale-105 ${filter === "accepted" ? "ring-2 ring-green-500" : ""
            }`}
        >
          <p className="text-gray-500">Accepted</p>
          <h2 className="text-4xl font-bold text-green-600 mt-2">
            {accepted}
          </h2>
        </div>

        {/* REJECTED */}
        <div
          onClick={() => setFilter("rejected")}
          className={`card text-center cursor-pointer transition hover:scale-105 ${filter === "rejected" ? "ring-2 ring-red-500" : ""
            }`}
        >
          <p className="text-gray-500">Rejected</p>
          <h2 className="text-4xl font-bold text-red-600 mt-2">
            {rejected}
          </h2>
        </div>

      </div>


      {/* SEEKER SEARCH */}
      {user.role === "seeker" && <NearbyDonors />}

      {/* REQUESTS */}
      <div>
        <p className="text-gray-500">
          Showing: <span className="font-semibold capitalize">{filter}</span> requests
        </p>

        <h2 className="text-3xl font-bold mb-6">
          {user.role === "donor"
            ? "Received Requests"
            : "Sent Requests"}
        </h2>

        {requests.length === 0 && (
          <p className="text-gray-500">No requests yet.</p>
        )}

        <div className="space-y-6">
          {filteredRequests.map((req) => (
            <div key={req.id} className="card">

              <div className="flex justify-between items-center">
                <div>
                  <h3 className="text-xl font-semibold">
                    {user.role === "donor"
                      ? req.seeker_name
                      : req.donor_name}
                  </h3>

                  <p className="text-gray-600">
                    Organ: {req.organ_type?.toUpperCase()}
                  </p>

                  <p className="text-gray-500">
                    Urgency: {req.urgency.toUpperCase()}
                  </p>
                </div>

                <span className="px-4 py-1 rounded-full bg-gray-200">
                  {req.status.toUpperCase()}
                </span>
              </div>

              {user.role === "donor" && req.status === "pending" && (
                <div className="flex gap-4 mt-4">
                  <button
                    onClick={() => acceptRequest(req.id)}
                    className="bg-green-500 text-white px-4 py-2 rounded-xl"
                  >
                    Accept
                  </button>

                  <button
                    onClick={() => rejectRequest(req.id)}
                    className="bg-red-500 text-white px-4 py-2 rounded-xl"
                  >
                    Reject
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}
