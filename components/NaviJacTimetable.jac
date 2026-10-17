import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.badge { Badge }
import from .ui.select { Select, SelectTrigger, SelectValue, SelectContent, SelectGroup, SelectItem }
import from .NaviJacThemeToggle { NaviJacThemeToggle }
import from "@jac/runtime" { Link, jacIsLoggedIn }
sv import from ..services.naviJacService { NaviJacTimetableEntry, get_my_timetable, create_timetable_entry, preview_timetable_csv, import_timetable_csv }

def:pub NaviJacTimetable() -> JsxElement {
    has sessions: list[NaviJacTimetableEntry] = [],
        loading: bool = True,
        subject: str = "",
        weekday: str = "Monday",
        start_time: str = "09:00",
        end_time: str = "10:00",
        building_id: str = "",
        room_id: str = "",
        location_name: str = "",
        notes: str = "",
        csv_text: str = "",
        csv_preview: list[dict] = [],
        csv_errors: list[str] = [],
        feedback: str = "";

    async can with entry {
        if jacIsLoggedIn() { sessions = await get_my_timetable(); }
        loading = False;
    }

    def update_subject(e: ChangeEvent) { subject = e.target.value; }
    def update_start(e: ChangeEvent) { start_time = e.target.value; }
    def update_end(e: ChangeEvent) { end_time = e.target.value; }
    def update_location(e: ChangeEvent) { location_name = e.target.value; }
    def update_notes(e: ChangeEvent) { notes = e.target.value; }
    def update_csv(e: ChangeEvent) { csv_text = e.target.value; }
    def load_csv_file(e: ChangeEvent) {
        file = e.target.files[0];
        if not file { return; }
        if not file.name.lower().endswith(".csv") { feedback = "Choose a .csv timetable file."; return; }
        reader: any = new(FileReader);
        reader.onload = lambda (_event: Event) { csv_text = reader.result as str; feedback = "CSV file loaded. Preview it before import."; };
        reader.readAsText(file);
    }

    async def save_session(e: FormEvent) {
        e.preventDefault();
        if not jacIsLoggedIn() { feedback = "Sign in to save a personal timetable."; return; }
        result = await create_timetable_entry(subject, weekday, start_time, end_time, building_id, room_id, location_name, notes);
        feedback = result["message"] as str;
        if result["ok"] as bool { sessions = await get_my_timetable(); subject = ""; location_name = ""; notes = ""; }
    }

    async def preview_csv -> None {
        if not jacIsLoggedIn() { feedback = "Sign in to preview a private timetable upload."; return; }
        result = await preview_timetable_csv(csv_text);
        csv_preview = result["rows"] as list[dict];
        csv_errors = result["errors"] as list[str];
        feedback = "CSV preview ready. Check every room name before importing.";
    }

    async def import_csv -> None {
        if not jacIsLoggedIn() { feedback = "Sign in to import your private timetable."; return; }
        result = await import_timetable_csv(csv_text);
        feedback = result["message"] as str;
        if result["ok"] as bool { sessions = await get_my_timetable(); csv_text = ""; csv_preview = []; csv_errors = []; }
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background"><div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-3 px-5 py-4 sm:px-8"><div className="flex items-center gap-4"><Link to="/" className="font-semibold text-foreground">NaviJac</Link><span className="text-sm text-muted-foreground">Personal timetable</span></div><div className="flex items-center gap-3"><Link to="/creator" className="text-sm text-primary">Map creator</Link><NaviJacThemeToggle /></div></div></header>
        <main className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-5 py-7 sm:px-8">
            <section className="flex flex-wrap items-end justify-between gap-4"><div><h1 className="text-3xl font-semibold tracking-tight">Weekly timetable</h1><p className="mt-1 text-sm text-muted-foreground">Keep your class and event schedule private to your account.</p></div><Badge variant="outline">Private to your account</Badge></section>
            {if not jacIsLoggedIn() { <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950">Sign in through the creator workspace to use a personal timetable. Personal entries are never published.</div> }}
            <div className="grid min-w-0 gap-5 xl:grid-cols-[minmax(0,1fr)_22rem]">
                <Card className="shadow-sm"><CardHeader><CardTitle>This week</CardTitle><CardDescription>Sessions use the times entered in your current local timetable.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">{if loading { <p className="rounded-md bg-muted p-4 text-sm text-muted-foreground">Loading your timetable…</p>; skip; }}{if not loading and len(sessions) == 0 { <div className="flex flex-col gap-2 rounded-lg border border-dashed bg-background p-8 text-center"><p className="font-medium">No sessions saved yet</p><p className="text-sm text-muted-foreground">Add a session manually or preview a CSV schedule.</p></div>; skip; }}{for session in sessions { <article key={jid(session)} className="flex flex-wrap items-center justify-between gap-3 rounded-lg border bg-background p-4"><div><p className="font-semibold">{session.subject}</p><p className="text-sm text-muted-foreground">{session.weekday} · {session.start_time}–{session.end_time}</p><p className="text-sm text-muted-foreground">{session.location_name if len(session.location_name) > 0 else "Location not assigned"}</p></div><Badge variant="secondary">{session.weekday}</Badge></article> }}</CardContent></Card>
                <aside className="flex flex-col gap-5">
                    <Card className="shadow-sm"><CardHeader><CardTitle>Add a session</CardTitle><CardDescription>End time must be later than start; overlaps are rejected.</CardDescription></CardHeader><CardContent><form className="flex flex-col gap-3" onSubmit={save_session}><label className="flex flex-col gap-1 text-sm font-medium">Subject or event<Input value={subject} onChange={update_subject} placeholder="Lecture or event name" /></label><label className="flex flex-col gap-1 text-sm font-medium">Day<Select value={weekday} onValueChange={lambda (value: str) { weekday = value; }}><SelectTrigger><SelectValue placeholder="Choose day" /></SelectTrigger><SelectContent><SelectGroup>{for day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"] { <SelectItem key={day} value={day}>{day}</SelectItem> }}</SelectGroup></SelectContent></Select></label><div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1 text-sm font-medium">Start<Input type="time" value={start_time} onChange={update_start} /></label><label className="flex flex-col gap-1 text-sm font-medium">End<Input type="time" value={end_time} onChange={update_end} /></label></div><label className="flex flex-col gap-1 text-sm font-medium">Room or location<Input value={location_name} onChange={update_location} placeholder="Optional, verify room manually" /></label><label className="flex flex-col gap-1 text-sm font-medium">Notes<Input value={notes} onChange={update_notes} placeholder="Optional" /></label><Button type="submit" disabled={not jacIsLoggedIn()}>Save session</Button></form></CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Preview CSV</CardTitle><CardDescription>Required headers: subject,weekday,start_time,end_time. Optional: location.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><label className="flex flex-col gap-1 text-sm font-medium">Upload CSV file<input type="file" accept=".csv,text/csv" onChange={load_csv_file} disabled={not jacIsLoggedIn()} className="rounded-md border bg-background p-2 text-sm" /></label><label className="flex flex-col gap-1 text-sm font-medium">Paste CSV rows<textarea className="min-h-32 rounded-md border bg-background p-3 text-sm" value={csv_text} onChange={update_csv} placeholder="subject,weekday,start_time,end_time,location" /></label><Button variant="outline" onClick={preview_csv} disabled={not jacIsLoggedIn()}>Preview and validate</Button>{if len(csv_preview) > 0 and len(csv_errors) == 0 { <Button onClick={import_csv} disabled={not jacIsLoggedIn()}>Import valid CSV rows</Button> }}{for error in csv_errors { <p key={error} className="text-sm text-destructive">{error}</p> }}{for row in csv_preview { <div key={str(row["subject"]) + str(row["weekday"])} className="rounded-md border bg-background p-3 text-sm"><p className="font-medium">{row["subject"] as str}</p><p className="text-muted-foreground">{row["weekday"] as str} · {row["start_time"] as str}–{row["end_time"] as str}</p><p className="text-xs text-amber-800">Preview only. Confirm location and save each valid session manually.</p></div> }}</CardContent></Card>
                    {feedback and <p role="status" className="rounded-lg border bg-card p-3 text-sm">{feedback}</p>}
                </aside>
            </div>
        </main>
    </div>;
}
