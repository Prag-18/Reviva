import { useEffect, useState } from "react";
import API from "../services/api";

export default function Profile() {
    const [user, setUser] = useState(null);
    const [isEditing, setIsEditing] = useState(false);
    const [formData, setFormData] = useState({
        name: "",
        phone: "",
        blood_group: "",
    });

    const fetchUser = async () => {
        try {
            const res = await API.get("/me");
            setUser(res.data);
            setFormData({
                phone: res.data.phone,
                donation_type: res.data.donation_type,
                available: res.data.available,
                role: res.data.role,
            });


        } catch (err) {
            console.error("Error fetching user", err);
        }
    };

    useEffect(() => {
        fetchUser();
    }, []);

    const handleUpdate = async () => {
        try {
            await API.put("/users/me", formData);
            alert("Profile updated!");
            setIsEditing(false);
            fetchUser();
        } catch (error) {
            alert("Update failed!");
        }
    };

    if (!user) return <div className="p-10 text-center">Loading...</div>;

    return (
        <div className="max-w-xl mx-auto mt-10 card">
            <h2 className="text-2xl font-bold text-rose-600 mb-6">
                My Profile
            </h2>

            {!isEditing ? (
                <>
                    <p><strong>Name:</strong> {user.name}</p>
                    <p><strong>Email:</strong> {user.email}</p>
                    <p><strong>Blood Group:</strong> {user.blood_group}</p>
                    <p><strong>Phone:</strong> {user.phone}</p>
                    <p><strong>Donation Type:</strong> {user.donation_type}</p>
                    <p><strong>Available:</strong> {user.available ? "Yes" : "No"}</p>


                    <button
                        onClick={() => setIsEditing(true)}
                        className="primary-btn mt-5 w-full"
                    >
                        Edit Profile
                    </button>
                </>
            ) : (
                <>
                    <input
                        className="form-input w-full mb-3"
                        value={formData.phone}
                        onChange={(e) =>
                            setFormData({ ...formData, phone: e.target.value })
                        }
                    />

                    <select
                        className="form-input w-full mb-3"
                        value={formData.donation_type}
                        onChange={(e) =>
                            setFormData({ ...formData, donation_type: e.target.value })
                        }
                    >
                        <option value="blood">Blood</option>
                        <option value="kidney">Kidney</option>
                        <option value="liver">Liver</option>
                        <option value="heart">Heart</option>
                        <option value="cornea">Cornea</option>
                        <option value="bone_marrow">Bone Marrow</option>
                    </select>
                    <select
                        className="form-input w-full mb-3"
                        value={formData.role}
                        onChange={(e) =>
                            setFormData({ ...formData, role: e.target.value })
                        }
                    >
                        <option value="donor">Donor</option>
                        <option value="seeker">Seeker</option>
                    </select>

                    <label className="flex items-center gap-2">
                        <input
                            type="checkbox"
                            checked={formData.available}
                            onChange={(e) =>
                                setFormData({ ...formData, available: e.target.checked })
                            }
                        />
                        Available for Donation
                    </label>


                    <button
                        onClick={handleUpdate}
                        className="primary-btn w-full"
                    >
                        Save Changes
                    </button>

                    <button
                        onClick={() => setIsEditing(false)}
                        className="mt-3 text-gray-500 underline w-full"
                    >
                        Cancel
                    </button>
                </>
            )}
        </div>
    );
}
