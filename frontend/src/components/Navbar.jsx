import { Link, useNavigate } from "react-router-dom";

export default function Navbar({ user }) {
  const navigate = useNavigate();

  const logout = () => {
    localStorage.removeItem("token");
    navigate("/");
  };

  return (
    <nav className="bg-white shadow-lg px-8 py-4 flex justify-between items-center sticky top-0 z-50">

      {/* Logo */}
      <div
        className="text-2xl font-bold text-rose-600 cursor-pointer"
        onClick={() => navigate("/dashboard")}
      >
        ❤️ Reviva
      </div>

      {/* Links */}
      {user && (
        <div className="flex items-center gap-6">

          <Link
            to="/dashboard"
            className="text-gray-600 hover:text-rose-600 font-medium"
          >
            Dashboard
          </Link>

          <Link
            to="/requests"
            className="text-gray-600 hover:text-rose-600 font-medium"
          >
            Requests
          </Link>

          <span className="bg-rose-100 text-rose-600 px-3 py-1 rounded-full text-sm font-semibold">
            {user.role}
          </span>

          <button
            onClick={logout}
            className="bg-rose-500 hover:bg-rose-600 text-white px-4 py-2 rounded-xl"
          >
            Logout
          </button>
        </div>
      )}

    </nav>
  );
}
