import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let opciones: [(titulo: String, segundos: Int?)] = [
        ("30 minutos", 1800),
        ("1 hora", 3600),
        ("2 horas", 7200),
        ("3 horas", 10800),
        ("4 horas", 14400),
        ("5 horas", 18000),
        ("Infinito", nil)
    ]

    private var statusItem: NSStatusItem!
    private var proceso: Process?
    private var indiceActivo: Int?
    private var fin: Date?
    private var timer: Timer?
    private let estadoItem = NSMenuItem(title: "Inactivo", action: nil, keyEquivalent: "")
    private let detenerItem = NSMenuItem(title: "Detener", action: #selector(detenerAccion), keyEquivalent: "")
    private var opcionItems: [NSMenuItem] = []
    private let reposoItem = NSMenuItem(title: "Desactivar reposo del sistema (pmset)", action: #selector(alternarReposo), keyEquivalent: "")
    private var reposoDesactivado = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        estadoItem.isEnabled = false
        menu.addItem(estadoItem)
        menu.addItem(.separator())

        for (i, opcion) in opciones.enumerated() {
            let item = NSMenuItem(title: opcion.titulo, action: #selector(elegir(_:)), keyEquivalent: "")
            item.target = self
            item.tag = i
            menu.addItem(item)
            opcionItems.append(item)
        }

        menu.addItem(.separator())
        detenerItem.target = self
        menu.addItem(detenerItem)
        menu.addItem(.separator())
        reposoItem.target = self
        menu.addItem(reposoItem)
        menu.addItem(.separator())
        let salir = NSMenuItem(title: "Salir", action: #selector(salir), keyEquivalent: "q")
        salir.target = self
        menu.addItem(salir)

        statusItem.menu = menu
        reposoDesactivado = leerReposoDesactivado()
        refrescar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        detener()
    }

    func menuWillOpen(_ menu: NSMenu) {
        reposoDesactivado = leerReposoDesactivado()
        refrescar()
    }

    @objc private func alternarReposo() {
        let valor = leerReposoDesactivado() ? 0 : 1
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", "do shell script \"/usr/bin/pmset -a disablesleep \(valor)\" with administrator privileges"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.reposoDesactivado = self.leerReposoDesactivado()
                self.refrescar()
            }
        }
        try? p.run()
    }

    private func leerReposoDesactivado() -> Bool {
        let p = Process()
        let salida = Pipe()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["-g"]
        p.standardOutput = salida
        p.standardError = FileHandle.nullDevice
        guard (try? p.run()) != nil else { return false }
        let datos = salida.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        let texto = String(data: datos, encoding: .utf8) ?? ""
        for linea in texto.split(separator: "\n") where linea.contains("SleepDisabled") {
            return linea.split(separator: " ").last == "1"
        }
        return false
    }

    @objc private func elegir(_ sender: NSMenuItem) {
        iniciar(indice: sender.tag)
    }

    @objc private func detenerAccion() {
        detener()
        refrescar()
    }

    @objc private func salir() {
        NSApp.terminate(nil)
    }

    private func iniciar(indice: Int) {
        detener()

        let segundos = opciones[indice].segundos
        var argumentos = ["-d", "-w", String(ProcessInfo.processInfo.processIdentifier)]
        if let segundos {
            argumentos += ["-t", String(segundos)]
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = argumentos
        p.terminationHandler = { [weak self] terminado in
            DispatchQueue.main.async {
                guard let self, self.proceso === terminado else { return }
                self.limpiar()
                self.refrescar()
            }
        }

        do {
            try p.run()
        } catch {
            limpiar()
            refrescar()
            return
        }

        proceso = p
        indiceActivo = indice
        fin = segundos.map { Date().addingTimeInterval(TimeInterval($0)) }

        let t = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.refrescar()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        refrescar()
    }

    private func detener() {
        let p = proceso
        limpiar()
        if let p, p.isRunning {
            p.terminate()
        }
    }

    private func limpiar() {
        proceso = nil
        indiceActivo = nil
        fin = nil
        timer?.invalidate()
        timer = nil
    }

    private func refrescar() {
        let activo = proceso != nil
        reposoItem.state = reposoDesactivado ? .on : .off
        let simbolo = activo || reposoDesactivado ? "cup.and.saucer.fill" : "cup.and.saucer"
        let imagen = NSImage(systemSymbolName: simbolo, accessibilityDescription: "Caffeinate")
        imagen?.isTemplate = true
        statusItem.button?.image = imagen
        statusItem.button?.toolTip = activo ? "Caffeinate activo" : "Caffeinate inactivo"

        for item in opcionItems {
            item.state = item.tag == indiceActivo ? .on : .off
        }
        detenerItem.isEnabled = activo

        guard activo else {
            estadoItem.title = "Inactivo"
            return
        }
        guard let fin else {
            estadoItem.title = "Activo: sin límite"
            return
        }
        let restante = max(0, Int(fin.timeIntervalSinceNow.rounded(.up)))
        let minutos = (restante + 59) / 60
        let h = minutos / 60
        let m = minutos % 60
        estadoItem.title = h > 0 ? "Activo: quedan \(h) h \(m) min" : "Activo: quedan \(m) min"
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
