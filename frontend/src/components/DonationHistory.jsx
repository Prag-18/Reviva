import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import API from "../services/api";

export default function DonationHistory() {
  const navigate = useNavigate();

  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);

  // ================= FETCH HISTORY =================
  const fetchHistory = async () => {
    try {
      const res = await API.get("/donation-history");
      setHistory(res.data);
    } catch (err) {
      console.error("Error fetching donation history", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, []);

  if (loading) {
    return <div className="p-10 text-center">Loading...</div>;
  }

  return (
    <div className="max-w-5xl mx-auto px-6 py-10 space-y-8">

      {/* HEADER */}
      <div className="flex justify-between items-center">
        <h2 className="text-3xl font-bold text-rose-600">
          Donation History
        </h2>

        <button
          onClick={() => navigate("/dashboard")}
          className="bg-gray-200 px-4 py-2 rounded-lg hover:bg-gray-300 transition"
        >
          Back to Dashboard
        </button>
      </div>

      {/* EMPTY STATE */}
      {history.length === 0 && (
        <div className="card text-center">
          <p className="text-gray-500">No donation history yet.</p>
        </div>
      )}

      {/* HISTORY CARDS */}
      <div className="space-y-6">
        {history.map((item) => (
          <div key={item.id} className="card hover:-translate-y-1 transition">

            <div className="flex justify-between items-center">

              <div>
                <h3 className="text-xl font-semibold">
                  {item.organ_type?.toUpperCase()}
                </h3>

                <p className="text-gray-500 text-sm mt-1">
                  Date:{" "}
                  {item.created_at
                    ? new Date(item.created_at).toLocaleDateString()
                    : "N/A"}
                </p>
              </div>

              <span
                className={`px-4 py-1 rounded-full text-sm font-semibold ${
                  item.status === "accepted"
                    ? "bg-green-100 text-green-700"
                    : item.status === "pending"
                    ? "bg-yellow-100 text-yellow-700"
                    : "bg-red-100 text-red-700"
                }`}
              >
                {item.status?.toUpperCase()}
              </span>

            </div>

          </div>
        ))}
      </div>

    </div>
  );
}
