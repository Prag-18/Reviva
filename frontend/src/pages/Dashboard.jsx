import { useEffect, useState } from "react";
import API from "../services/api";
import NearbyDonors from "./NearbyDonors";

export default function Dashboard() {
    const [user, setUser] = useState(null);
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);

    const [notification, setNotification] = useState("");

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
            alert(err.response?.data?.detail || "Error accepting request");
        }
    };

    // ================= REJECT REQUEST =================
    const rejectRequest = async (id) => {
        try {
            await API.put(`/reject-request/${id}`);
            fetchRequests(user.id);
        } catch (err) {
            alert(err.response?.data?.detail || "Error rejecting request");
        }
    };

    // ================= WEBSOCKET =================
    useEffect(() => {
        if (!user) return;

        const ws = new WebSocket(`ws://127.0.0.1:8000/ws/${user.id}`);

        ws.onmessage = (event) => {
            if (event.data === "new_request") {
                setNotification("🔔 New donation request received!");
                fetchRequests(user.id);
                setTimeout(() => setNotification(""), 4000);
            }
        };

        return () => ws.close();
    }, [user]);

    // ================= INITIAL LOAD =================
    useEffect(() => {
        const loadData = async () => {
            await fetchUser();
        };
        loadData();
    }, []);

    useEffect(() => {
        if (user) {
            fetchRequests(user.id);
        }
    }, [user]);

    if (loading || !user) {
        return <div className="p-10 text-center">Loading...</div>;
    }

    // ================= CALCULATE STATS =================
    const total = requests.length;
    const pending = requests.filter((r) => r.status === "pending").length;
    const accepted = requests.filter((r) => r.status === "accepted").length;

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

    return (
        <div className="p-8 space-y-8">

            {/* Notification */}
            {notification && (
                <div className="bg-rose-500 text-white px-6 py-3 rounded-xl shadow-lg">
                    {notification}
                </div>
            )}

            {/* Welcome Section */}
            <div>
                <h1 className="text-3xl font-bold text-rose-600">
                    Welcome, {user.name} 👋
                </h1>
                <p className="text-gray-600">
                    Role: {user.role} | Blood Group: {user.blood_group}
                </p>
            </div>

            {/* Stats Cards */}
            <div className="grid md:grid-cols-3 gap-6">
                <div className="card text-center">
                    <p>Total Requests</p>
                    <h2 className="text-3xl font-bold text-rose-600">{total}</h2>
                </div>

                <div className="card text-center">
                    <p>Pending</p>
                    <h2 className="text-3xl font-bold text-yellow-500">{pending}</h2>
                </div>

                <div className="card text-center">
                    <p>Accepted</p>
                    <h2 className="text-3xl font-bold text-green-600">{accepted}</h2>
                </div>
            </div>

            {/* Donor Availability Toggle */}
            {user.role === "donor" && (
                <button
                    onClick={toggleAvailability}
                    className={`primary-btn ${user.available
                        ? "bg-green-500 hover:bg-green-600"
                        : "bg-red-500 hover:bg-red-600"
                        }`}
                >
                    {user.available ? "Set Unavailable" : "Set Available"}
                </button>
            )}

            {/* Seeker Nearby Donors */}
            {user.role === "seeker" && <NearbyDonors />}

            {/* Requests Section */}
            <div>
                <h2 className="text-2xl font-semibold mb-4">
                    {user.role === "donor"
                        ? "Received Requests"
                        : "Sent Requests"}
                </h2>

                <div className="space-y-6">
                    {requests.length === 0 && (
                        <p className="text-gray-500">No requests yet.</p>
                    )}

                    {requests.map((req) => (
                        <div key={req.id} className="card">
                            <div className="flex justify-between items-center">
                                <div>
                                    <h3 className="text-lg font-semibold">
                                        {user.role === "donor"
                                            ? req.seeker_name
                                            : req.donor_name}
                                    </h3>

                                    {req.organ_type === "blood" && (
                                        <p className="text-sm text-gray-500">
                                            Blood Group: {req.seeker_blood_group}
                                        </p>
                                    )}

                                    <p className="text-sm text-gray-600 font-medium mt-1">
                                        Organ: {req.organ_type?.toUpperCase()}
                                    </p>


                                    <p className={`mt-2 ${urgencyColors[req.urgency]}`}>
                                        Urgency: {req.urgency.toUpperCase()}
                                    </p>
                                </div>

                                <span
                                    className={`px-3 py-1 rounded-full text-sm font-semibold ${statusColors[req.status]
                                        }`}
                                >
                                    {req.status.toUpperCase()}
                                </span>
                            </div>

                            {/* Accept / Reject Buttons */}
                            {user.role === "donor" &&
                                req.status === "pending" && (
                                    <div className="flex gap-4 mt-4">
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
            </div>
        </div>
    );
}
