import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.badge { Badge }
import from .NaviJacThemeToggle { NaviJacThemeToggle }
import from "@jac/runtime" { Link, jacLogin, jacSignup, jacLogout, jacIsLoggedIn }
sv import from ..services.naviJacService { NaviJacMap, get_owned_maps, create_owned_map, update_owned_map, publish_owned_map }

def:pub NaviJacCreator() -> JsxElement {
    has maps: list[NaviJacMap] = [],
        name_text: str = "",
        description_text: str = "",
        location_text: str = "",
        email_text: str = "",
        password_text: str = "",
        feedback: str = "",
        loading: bool = False,
        signed_in: bool = False;

    async can with entry {
        if jacIsLoggedIn() {
            signed_in = True;
            loading = True;
            maps = await get_owned_maps();
            loading = False;
        }
    }

    def update_name(e: ChangeEvent) { name_text = e.target.value; }
    def update_description(e: ChangeEvent) { description_text = e.target.value; }
    def update_location(e: ChangeEvent) { location_text = e.target.value; }
    def update_email(e: ChangeEvent) { email_text = e.target.value; }
    def update_password(e: ChangeEvent) { password_text = e.target.value; }

    async def handle_register(e: FormEvent) {
        e.preventDefault();
        result: dict | None = None;
        login_ok: bool = False;
        if len(email_text.strip()) == 0 or len(password_text) < 8 { feedback = "Enter an email and a password with at least 8 characters."; return; }
        result = await jacSignup(email_text, password_text);
        if not result["success"] { feedback = "Account registration failed. The email may already be registered."; return; }
        login_ok = await jacLogin(email_text, password_text);
        if not login_ok { feedback = "Account created, but sign-in failed. Please sign in."; return; }
        signed_in = True;
        loading = True;
        maps = await get_owned_maps();
        loading = False;
        feedback = "Creator account ready.";
    }

    async def handle_login(e: FormEvent) {
        e.preventDefault();
        login_ok: bool = False;
        if len(email_text.strip()) == 0 or len(password_text) == 0 { feedback = "Enter your email and password."; return; }
        login_ok = await jacLogin(email_text, password_text);
        if not login_ok { feedback = "Sign-in failed. Check your email and password."; return; }
        signed_in = True;
        loading = True;
        maps = await get_owned_maps();
        loading = False;
        feedback = "Signed in.";
    }

    async def handle_create(e: FormEvent) {
        e.preventDefault();
        if len(name_text.strip()) == 0 { feedback = "Enter a building name."; return; }
        created = await create_owned_map(name_text, description_text, location_text);
        if created is None { feedback = "Map could not be created."; return; }
        maps = maps + [created];
        name_text = ""; description_text = ""; location_text = "";
        feedback = "Private draft created. Add a floor plan and verify its map before publishing.";
    }

    async def toggle_publish(map_id: str, currently_public: bool) {
        updated = await publish_owned_map(map_id, not currently_public);
        if updated is None { feedback = "Only the map owner can publish this draft."; }
        else { feedback = "Publication status updated."; maps = await get_owned_maps(); }
    }

    def handle_logout(e: MouseEvent) { jacLogout(); signed_in = False; maps = []; feedback = "Signed out."; }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background"><div className="mx-auto flex max-w-6xl items-center justify-between gap-3 px-5 py-4"><Link to="/" className="text-lg font-semibold text-foreground">NaviJac</Link><div className="flex flex-wrap items-center gap-4 text-sm"><Link to="/" className="text-primary">Explore maps</Link><Link to="/maps/sumanadasa/first-floor/route" className="text-primary">Featured demo</Link><Link to="/timetable" className="text-primary">My timetable</Link><NaviJacThemeToggle /></div></div></header>
        <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-5 py-8 sm:px-8">
            <section><h1 className="text-3xl font-semibold tracking-tight">Map creator workspace</h1><p className="mt-2 max-w-2xl text-muted-foreground">Create private building drafts and manage only maps owned by your signed-in account.</p></section>
            {if not signed_in {
                <div className="grid gap-5 lg:grid-cols-2">
                    <Card className="shadow-sm"><CardHeader><CardTitle>Sign in</CardTitle><CardDescription>Return to your saved building maps.</CardDescription></CardHeader><CardContent><form className="flex flex-col gap-4" onSubmit={handle_login}><label className="flex flex-col gap-1 text-sm font-medium">Email<Input type="email" value={email_text} onChange={update_email} placeholder="you@example.org" /></label><label className="flex flex-col gap-1 text-sm font-medium">Password<Input type="password" value={password_text} onChange={update_password} placeholder="Your password" /></label><Button type="submit">Sign in</Button></form></CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Create a creator account</CardTitle><CardDescription>Accounts are required to own draft maps.</CardDescription></CardHeader><CardContent><form className="flex flex-col gap-4" onSubmit={handle_register}><label className="flex flex-col gap-1 text-sm font-medium">Email<Input type="email" value={email_text} onChange={update_email} placeholder="you@example.org" /></label><label className="flex flex-col gap-1 text-sm font-medium">Password<Input type="password" value={password_text} onChange={update_password} placeholder="At least 8 characters" /></label><Button type="submit" variant="outline">Create account</Button></form></CardContent></Card>
                </div>
            } else {
                <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_20rem]">
                    <Card className="shadow-sm"><CardHeader className="flex flex-row items-start justify-between gap-4"><div><CardTitle>Your maps</CardTitle><CardDescription>Private drafts are visible only to their owner; publication copies them into the public directory.</CardDescription></div><Button variant="outline" onClick={handle_logout}>Sign out</Button></CardHeader><CardContent className="flex flex-col gap-3">{if loading { <p className="rounded-md bg-muted p-4 text-sm text-muted-foreground">Loading your maps…</p> }}{if not loading and len(maps) == 0 { <p className="rounded-md border border-dashed p-6 text-sm text-muted-foreground">No owned maps yet. Create a building draft to begin.</p> }}{for m in maps { <article key={jid(m)} className="flex flex-wrap items-center justify-between gap-3 rounded-lg border bg-background p-4"><div><h2 className="font-semibold">{m.name}</h2><p className="text-sm text-muted-foreground">{m.description if len(m.description) > 0 else "No description"}</p><Badge variant="outline">{"Published" if m.is_public else "Private draft"}</Badge></div><Button size="sm" variant="outline" onClick={lambda { toggle_publish(jid(m), m.is_public); }}>{"Unpublish" if m.is_public else "Publish map"}</Button></article> }}</CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Create a building</CardTitle><CardDescription>New maps start as private drafts.</CardDescription></CardHeader><CardContent><form className="flex flex-col gap-3" onSubmit={handle_create}><label className="flex flex-col gap-1 text-sm font-medium">Building name<Input value={name_text} onChange={update_name} placeholder="Building name" /></label><label className="flex flex-col gap-1 text-sm font-medium">Description<Input value={description_text} onChange={update_description} placeholder="Optional overview" /></label><label className="flex flex-col gap-1 text-sm font-medium">Location<Input value={location_text} onChange={update_location} placeholder="City or campus" /></label><Button type="submit">Create private draft</Button></form></CardContent></Card>
                </div>
            }}
            {feedback and <p role="status" className="rounded-lg border bg-card p-4 text-sm">{feedback}</p>}
            <Card className="border-amber-300 shadow-sm"><CardContent className="pt-5 text-sm text-amber-950">The featured Sumanadasa map remains read-only. New drafts can be owned and published, but full floor editing and image alignment are not available for creator maps yet.</CardContent></Card>
        </main>
    </div>;
}
