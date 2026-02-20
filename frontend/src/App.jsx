import { useEffect, useState } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Requests from "./pages/Requests";
import API from "./services/api";
import Profile from "./components/Profile";
import DonationHistory from "./components/DonationHistory";


function PrivateRoute({ children }) {
  const token = localStorage.getItem("token");
  return token ? children : <Navigate to="/" />;
}

function App() {
  const [user, setUser] = useState(null);
  const token = localStorage.getItem("token");

  useEffect(() => {
    const fetchUser = async () => {
      if (!token) return;

      try {
        const res = await API.get("/me");
        setUser(res.data);
      } catch (err) {
        console.error("Failed to fetch user");
      }
    };

    fetchUser();
  }, [token]);

  return (
    <Routes>
      <Route path="/" element={<Login setUser={setUser} />} />
      <Route path="/register" element={<Register />} />

      <Route
        path="/dashboard"
        element={
          <PrivateRoute>
            <Dashboard user={user} />
          </PrivateRoute>
        }
      />
      <Route path="/profile" element={<Profile />} />
      <Route path="/history" element={<DonationHistory />} />
      <Route
        path="/requests"
        element={
          <PrivateRoute>
            <Requests user={user} />
          </PrivateRoute>
        }
      />
    </Routes>
  );
}

export default App;
