import { useEffect, useState } from "react";
import API from "../services/api";
import NearbyDonors from "./NearbyDonors";
import Navbar from "../components/Navbar";
import { useNavigate } from "react-router-dom";

function Dashboard() {
    const [user, setUser] = useState(null);
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);
    const navigate = useNavigate();

    const fetchData = async () => {
        try {
            const userRes = await API.get("/me");
            setUser(userRes.data);

            const reqRes = await API.get(`/my-requests/${userRes.data.id}`);
            setRequests(reqRes.data);
        } catch (err) {
            console.error("Error fetching data", err);
            localStorage.removeItem("token");
            navigate("/");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    useEffect(() => {
        if (!user) return;

        const apiBaseUrl = API.defaults.baseURL || "http://127.0.0.1:8000";
        const wsBaseUrl = apiBaseUrl.replace(/^http/i, "ws");
        const socket = new WebSocket(`${wsBaseUrl}/ws/${user.id}`);

        socket.onopen = () => {
            console.log("WebSocket connected");
        };

        socket.onmessage = (event) => {
            if (event.data === "new_request") {
                fetchData();
            }
        };

        socket.onerror = (error) => {
            console.error("WebSocket error:", error);
        };

        socket.onclose = (event) => {
            console.warn("WebSocket closed:", event.code, event.reason || "No reason provided");
        };

        return () => {
            socket.close();
        };
    }, [user?.id]);




    const toggleAvailability = async () => {
        await API.put("/toggle-availability");
        fetchData();
    };

    const acceptRequest = async (id) => {
        await API.put(`/accept-request/${id}`);
        fetchData();
    };

    const rejectRequest = async (id) => {
        await API.put(`/reject-request/${id}`);
        fetchData();
    };

    if (loading) return <div className="p-10">Loading...</div>;
    if (!user) return null;

    const pendingCount = requests.filter(
        r => r.status === "pending"
    ).length;

    const acceptedCount = requests.filter(
        r => r.status === "accepted"
    ).length;

    const pendingRequests = requests.filter(
        r => r.status === "pending" && r.donor_id === user.id
    );

    const urgencyColor = {
        low: "bg-green-100 text-green-600",
        medium: "bg-yellow-100 text-yellow-600",
        high: "bg-orange-100 text-orange-600",
        critical: "bg-red-100 text-red-600"
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-rose-50 via-pink-50 to-red-100">

            {/* 🔔 Navbar */}
            <Navbar user={user} pendingRequests={pendingRequests} />

            <div className="p-10">

                {/* Header */}
                <div className="mb-10">
                    <h1 className="text-4xl font-bold text-rose-600">
                        Welcome, {user.name} 👋
                    </h1>
                    <p className="text-gray-600 mt-2">
                        Role: <span className="font-semibold">{user.role}</span>
                    </p>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-6 mb-10">

                    <div className="card text-center">
                        <h3 className="text-gray-500">Total Requests</h3>
                        <p className="text-3xl font-bold text-rose-600 mt-2">
                            {requests.length}
                        </p>
                    </div>

                    <div className="card text-center">
                        <h3 className="text-gray-500">Pending</h3>
                        <p className="text-3xl font-bold text-yellow-500 mt-2">
                            {pendingCount}
                        </p>
                    </div>

                    <div className="card text-center">
                        <h3 className="text-gray-500">Accepted</h3>
                        <p className="text-3xl font-bold text-green-600 mt-2">
                            {acceptedCount}
                        </p>
                    </div>

                </div>

                {/* ================= DONOR VIEW ================= */}
                {user.role === "donor" && (
                    <div>

                        <div className="mb-6">
                            <button
                                onClick={toggleAvailability}
                                className="primary-btn"
                            >
                                {user.available ? "Set Unavailable" : "Set Available"}
                            </button>
                        </div>

                        <h2
                            id="pending-section"
                            className="text-2xl font-semibold mb-6"
                        >
                            Received Requests
                        </h2>

                        <div className="grid gap-6">
                            {requests
                                .filter(r => r.donor_id === user.id)
                                .map(r => (
                                    <div key={r.id} className="card">

                                        <div className="flex justify-between items-center mb-3">
                                            <h3 className="font-semibold text-lg">
                                                Seeker: {r.seeker_name || "Unknown"}
                                            </h3>

                                            <span className={`px-3 py-1 rounded-full text-sm font-medium ${urgencyColor[r.urgency]}`}>
                                                {r.urgency}
                                            </span>
                                        </div>

                                        <p className="text-gray-600 mb-2">
                                            Status: <span className="font-semibold">{r.status}</span>
                                        </p>

                                        {r.status === "pending" && (
                                            <div className="flex gap-4 mt-4">
                                                <button
                                                    onClick={() => acceptRequest(r.id)}
                                                    className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg"
                                                >
                                                    Accept
                                                </button>

                                                <button
                                                    onClick={() => rejectRequest(r.id)}
                                                    className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg"
                                                >
                                                    Reject
                                                </button>
                                            </div>
                                        )}

                                    </div>
                                ))}
                        </div>

                    </div>
                )}

                {/* ================= SEEKER VIEW ================= */}
                {user.role === "seeker" && (
                    <div>

                        <h2 className="text-2xl font-semibold mb-6">
                            Find Nearby Donors
                        </h2>

                        <NearbyDonors />

                        <h2 className="text-2xl font-semibold mt-10 mb-6">
                            Sent Requests
                        </h2>

                        <div className="grid gap-6">
                            {requests
                                .filter(r => r.seeker_id === user.id)
                                .map(r => (
                                    <div key={r.id} className="card">
                                        <p>Urgency: {r.urgency}</p>
                                        <p>Status: {r.status}</p>
                                    </div>
                                ))}
                        </div>

                    </div>
                )}

            </div>
        </div>
    );
}

export default Dashboard;
