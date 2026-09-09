// ============================================
// AUTH HELPERS
// ============================================

async function getCurrentUser() {

    const { data, error } = await supabase.auth.getSession();

    if (error) return null;

    return data.session;
}

async function logout() {

    await supabase.auth.signOut();

    window.location.href = "login.html";
}

async function requireLogin() {

    const session = await getCurrentUser();

    if (!session) {

        window.location.href = "login.html";

        return null;
    }

    return session.user;
}

async function requireAdmin() {

    const user = await requireLogin();

    if (!user) return;

    const { data: profile } = await supabase

        .from("profiles")

        .select("role")

        .eq("id", user.id)

        .single();

    if (profile.role !== "admin") {

        window.location.href = "dashboard.html";
    }

    return user;
}