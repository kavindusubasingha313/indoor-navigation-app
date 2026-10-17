sv import from ..services.naviJacService { NaviJacMap, get_public_maps, create_public_map }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.badge { Badge }
import from "@jac/runtime" { Link }


def:pub NaviJacHome() -> JsxElement {
    has maps: list[NaviJacMap] = [],
        map_name: str = "",
        map_description: str = "",
        feedback: str = "",
        loading: bool = True;

    async can with entry {
        maps = await get_public_maps();
        loading = False;
    }

    def handle_name(e: ChangeEvent) { map_name = e.target.value; }
    def handle_description(e: ChangeEvent) { map_description = e.target.value; }

    async def handle_create -> None {
        feedback = "";
        if len(map_name.strip()) == 0 {
            feedback = "Enter a building name to continue.";
        } else {
            created = await create_public_map(map_name, map_description);
            if created is None {
                feedback = "A building name is required.";
            } else {
                maps = maps + [created];
                map_name = "";
                map_description = "";
                feedback = "Public building added.";
            }
        }
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background">
            <div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between gap-4 px-5 sm:px-8">
                <Link to="/" className="flex items-center gap-3 text-foreground no-underline">
                    <span className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground font-bold">N</span>
                    <span className="text-lg font-semibold tracking-tight">NaviJac</span>
                </Link>
                <Badge variant="secondary">Public map directory</Badge>
            </div>
        </header>
        <main className="mx-auto flex w-full max-w-7xl flex-col gap-8 px-5 py-8 sm:px-8 sm:py-12">
            <section className="grid gap-6 rounded-2xl border bg-card p-6 shadow-sm md:grid-cols-[1fr_auto] md:items-end md:p-9">
                <div className="flex max-w-3xl flex-col gap-4">
                    <Badge variant="outline" className="w-fit">Indoor navigation foundation</Badge>
                    <h1 className="text-balance text-3xl font-semibold leading-tight tracking-tight sm:text-4xl">Find your way through the building.</h1>
                    <p className="max-w-2xl text-base leading-relaxed text-muted-foreground">NaviJac brings public indoor maps and future route guidance into one place. This experimental foundation starts with a single building directory.</p>
                </div>
                <div className="flex flex-col gap-1 rounded-xl bg-muted/60 p-4 md:min-w-52">
                    <span className="text-sm font-medium">Designed for everyone</span>
                    <span className="text-sm text-muted-foreground">Public visitors can browse maps. Administrators and map creators manage map records.</span>
                </div>
            </section>

            <section className="flex flex-col gap-5">
                <div className="flex flex-wrap items-end justify-between gap-4">
                    <div className="flex flex-col gap-1">
                        <h2 className="text-2xl font-semibold tracking-tight">Public buildings</h2>
                        <p className="text-sm text-muted-foreground">Browse the maps made available to visitors.</p>
                    </div>
                    <span className="text-sm text-muted-foreground">{str(len(maps))} public maps</span>
                </div>
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Building directory</CardTitle>
                        <CardDescription>Map geometry and walkable routes will be added after locations are verified.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        {if loading {
                            <div className="rounded-xl border border-dashed bg-muted/30 p-8 text-center text-sm text-muted-foreground">Loading public maps…</div>
                            skip;
                        }}
                        {if len(maps) == 0 {
                            <div className="flex flex-col items-center gap-2 rounded-xl border border-dashed bg-muted/30 px-5 py-12 text-center">
                                <span className="text-base font-semibold">No public maps yet</span>
                                <span className="max-w-md text-sm text-muted-foreground">Create the first building record to establish the public directory. No room positions or routes are assumed.</span>
                            </div>
                            skip;
                        }}
                        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                            {for building in maps {
                                <article key={jid(building)} className="rounded-xl border bg-background p-5 shadow-sm transition-shadow hover:shadow-md">
                                    <div className="flex items-start justify-between gap-3">
                                        <div className="flex flex-col gap-1">
                                            <h3 className="text-lg font-semibold">{building.name}</h3>
                                            <p className="text-sm text-muted-foreground">{building.description if len(building.description) > 0 else "Building map foundation"}</p>
                                        </div>
                                        <Badge variant="secondary">Public</Badge>
                                    </div>
                                    <div className="mt-5 border-t pt-4 text-sm text-muted-foreground">{str(building.floor_count)} floor prepared for map data</div>
                                </article>
                            }}
                        </div>
                    </CardContent>
                </Card>
            </section>

            <section className="grid gap-5 lg:grid-cols-[1fr_1fr]">
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Creator foundation</CardTitle>
                        <CardDescription>Create a public building record for the experimental directory.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <form className="flex flex-col gap-4" onSubmit={lambda (e: FormEvent) { e.preventDefault(); handle_create(); }}>
                            <label className="flex flex-col gap-2 text-sm font-medium">Building name
                                <input className="h-10 rounded-md border bg-background px-3 font-normal shadow-sm outline-none focus-visible:ring-2 focus-visible:ring-ring" placeholder="For example, Engineering Building" value={map_name} onChange={handle_name} />
                            </label>
                            <label className="flex flex-col gap-2 text-sm font-medium">Description <span className="font-normal text-muted-foreground">Optional</span>
                                <textarea className="min-h-24 resize-y rounded-md border bg-background px-3 py-2 font-normal shadow-sm outline-none focus-visible:ring-2 focus-visible:ring-ring" placeholder="A short public description" value={map_description} onChange={handle_description} />
                            </label>
                            {feedback and <p role="status" className="text-sm text-muted-foreground">{feedback}</p>}
                            <Button type="submit" className="w-full sm:w-fit">Create public building</Button>
                        </form>
                    </CardContent>
                </Card>
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Roles and persistence</CardTitle>
                        <CardDescription>The groundwork for later administrator and map-creator workflows.</CardDescription>
                    </CardHeader>
                    <CardContent className="flex flex-col gap-3">
                        <div className="rounded-lg border bg-background p-4">
                            <p className="font-medium">Administrator and map creator</p>
                            <p className="mt-1 text-sm text-muted-foreground">Role values and account records are modeled. Sign-in and permissions are intentionally not enabled in this stage.</p>
                        </div>
                        <div className="rounded-lg border bg-background p-4">
                            <p className="font-medium">Public viewer</p>
                            <p className="mt-1 text-sm text-muted-foreground">Public map records are stored in Jac’s persistent graph and can be browsed without an account.</p>
                        </div>
                    </CardContent>
                </Card>
            </section>
            <footer className="border-t pt-5 text-xs text-muted-foreground">NaviJac experimental foundation · Map geometry and routes are not yet defined.</footer>
        </main>
    </div>;
}
