import UIKit

/// Ajustes de la app: controles, apariencia e información.
final class SettingsViewController: UITableViewController {
    private enum Row: Int, CaseIterable {
        case vibration
        case showControls
        case version

        var title: String {
            switch self {
            case .vibration: return "Vibración"
            case .showControls: return "Mostrar botones en pantalla"
            case .version: return "Versión"
            }
        }

        var defaultsKey: String {
            switch self {
            case .vibration: return "grasadroid.vibration"
            case .showControls: return "grasadroid.showControls"
            case .version: return ""
            }
        }
    }

    init() {
        super.init(style: .insetGrouped)
        title = "Ajustes"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Tabla

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Controles" : "Acerca de"
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.section == 0 {
            let row: Row = indexPath.row == 0 ? .vibration : .showControls
            cell.textLabel?.text = row.title
            cell.selectionStyle = .none
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.bool(forKey: row.defaultsKey)
            toggle.tag = row.rawValue
            toggle.addTarget(self, action: #selector(didToggle(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        } else {
            cell.textLabel?.text = Row.version.title
            cell.detailTextLabel?.text = "M2 · interfaz"
            cell.selectionStyle = .none
        }
        return cell
    }

    @objc private func didToggle(_ sender: UISwitch) {
        guard let row = Row(rawValue: sender.tag), !row.defaultsKey.isEmpty else { return }
        UserDefaults.standard.set(sender.isOn, forKey: row.defaultsKey)
    }
}
