import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { BellIcon } from "@heroicons/react/24/outline";

function Navbar({ user, pendingRequests = [] }) {
  const [open, setOpen] = useState(false);
  const [pulse, setPulse] = useState(false);
  const navigate = useNavigate();

  const pendingCount = pendingRequests.length;

  useEffect(() => {
    if (pendingCount > 0) {
      setPulse(true);
      setTimeout(() => setPulse(false), 2000);
    }
  }, [pendingCount]);

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user_id");
    navigate("/");
  };

  const scrollToPending = () => {
    const section = document.getElementById("pending-section");
    if (section) {
      section.scrollIntoView({ behavior: "smooth" });
    }
    setOpen(false);
  };

  return (
    <nav className="bg-white shadow-md px-10 py-4 flex justify-between items-center">

      <h1 className="text-2xl font-bold text-rose-600">
        ❤️ OrganConnect
      </h1>

      <div className="flex items-center gap-6">

        {/* 🔔 Notification Bell */}
        {user?.role === "donor" && (
          <div className="relative">

            <button
              onClick={() => setOpen(!open)}
              className={`relative ${pulse ? "animate-pulse" : ""}`}
            >
              <BellIcon className="h-7 w-7 text-rose-600" />
              
              {pendingCount > 0 && (
                <span className="absolute -top-2 -right-2 bg-red-500 text-white text-xs px-2 py-0.5 rounded-full">
                  {pendingCount}
                </span>
              )}
            </button>

            {/* Dropdown */}
            {open && (
              <div className="absolute right-0 mt-3 w-72 bg-white rounded-xl shadow-lg border border-gray-100 p-4">

                <h3 className="font-semibold mb-3">
                  Pending Requests
                </h3>

                {pendingCount === 0 && (
                  <p className="text-gray-500 text-sm">
                    No pending requests
                  </p>
                )}

                {pendingRequests.map((req) => (
                  <div
                    key={req.id}
                    className="border-b py-2 last:border-none cursor-pointer hover:bg-gray-50 rounded-md px-2"
                    onClick={scrollToPending}
                  >
                    <p className="text-sm font-medium">
                      {req.seeker_name}
                    </p>
                    <p className="text-xs text-gray-500">
                      Urgency: {req.urgency}
                    </p>
                  </div>
                ))}

              </div>
            )}

          </div>
        )}

        {/* Profile */}
        <div className="relative">
          <button
            onClick={handleLogout}
            className="bg-rose-100 px-4 py-2 rounded-full hover:bg-rose-200 transition text-rose-600 font-semibold"
          >
            Logout
          </button>
        </div>

      </div>

    </nav>
  );
}

export default Navbar;
