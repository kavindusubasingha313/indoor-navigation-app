import from .ui.badge { Badge }

def:pub NaviJacFloorMap() -> JsxElement {
    return <section className="flex flex-col gap-3 rounded-xl border bg-card p-4 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="text-lg font-semibold">Library · Ground floor</h2><p className="text-sm text-muted-foreground">Reconstructed from the supplied dimensioned plan</p></div><Badge variant="outline">Image-derived estimate</Badge></div>
        <div className="overflow-x-auto rounded-lg border bg-background p-2"><svg viewBox="0 0 960 620" className="mx-auto block h-auto w-full" role="img" aria-label="Estimated ground floor plan with rooms around a central open lobby and indicated door openings">
            <rect x="80" y="70" width="800" height="500" fill="#fafaf9" stroke="#292524" strokeWidth="5" />
            <rect x="82" y="72" width="200" height="120" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="182" y="126" textAnchor="middle" fontSize="14">IT unit (NDT)</text>
            <rect x="82" y="194" width="100" height="78" fill="#f5f5f4" stroke="#57534e" strokeWidth="2"/><text x="132" y="234" textAnchor="middle" fontSize="13">Female WC</text>
            <rect x="184" y="194" width="98" height="78" fill="#f5f5f4" stroke="#57534e" strokeWidth="2"/><text x="233" y="234" textAnchor="middle" fontSize="13">Store room</text>
            <rect x="82" y="274" width="100" height="96" fill="#f5f5f4" stroke="#57534e" strokeWidth="2"/><text x="132" y="324" textAnchor="middle" fontSize="13">Male WC</text>
            <rect x="382" y="72" width="200" height="120" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="482" y="126" textAnchor="middle" fontSize="13">Computer lab (RCDF)</text>
            <rect x="584" y="72" width="296" height="120" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="732" y="120" textAnchor="middle" fontSize="13">Seminar room (ITSDL)</text>
            <rect x="382" y="194" width="200" height="100" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="482" y="246" textAnchor="middle" fontSize="13">Staff lounge</text>
            <rect x="584" y="194" width="196" height="100" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="682" y="246" textAnchor="middle" fontSize="13">Ladies lunch room</text>
            <rect x="782" y="236" width="98" height="134" fill="#f5f5f4" stroke="#57534e" strokeWidth="2"/><text x="831" y="300" textAnchor="middle" fontSize="12">WC block</text>
            <rect x="184" y="396" width="196" height="172" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="282" y="478" textAnchor="middle" fontSize="13">Bindery section</text>
            <rect x="382" y="396" width="100" height="172" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="432" y="478" textAnchor="middle" fontSize="13">Bindery stores</text>
            <rect x="484" y="396" width="100" height="172" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="534" y="478" textAnchor="middle" fontSize="13">AQ stores</text>
            <rect x="586" y="396" width="194" height="172" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="683" y="478" textAnchor="middle" fontSize="13">Technical services</text>
            <rect x="782" y="396" width="98" height="172" fill="#e7e5e4" stroke="#57534e" strokeWidth="2"/><text x="831" y="478" textAnchor="middle" fontSize="12">Gents lunch</text>
            <path d="M284 194v170h496V294" fill="none" stroke="#ffffff" strokeWidth="12"/><text x="520" y="350" textAnchor="middle" fontSize="18" fontWeight="600" fill="#44403c">OPEN LOBBY / CIRCULATION</text>
            <path d="M382 192v24 M582 244h24 M780 294h24 M380 396v24 M780 396v24 M282 396v24" stroke="#ffffff" strokeWidth="9" />
            <text x="480" y="602" textAnchor="middle" fontSize="12" fill="#78716c">Door gaps and open circulation interpreted from the image; verify on site</text>
        </svg></div>
        <div className="grid gap-2 text-xs text-muted-foreground sm:grid-cols-2"><p><strong className="text-foreground">Scale source:</strong> printed 6 m dimension grid, applied as an approximate schematic reference.</p><p><strong className="text-foreground">Limit:</strong> reconstructed vector, not the original PDF/CAD; doorway widths, stairs and accessibility are not certified.</p></div>
    </section>;
}