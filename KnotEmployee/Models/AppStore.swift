import Observation

@Observable final class AppStore {
    var currentUser: StaffMember
    var staff: [StaffMember]
    var shift: [Shift]
    var openShifts: [OpenShift]
    var swaps: [Swap]
    var timeOff: [TimeOff]
    
    var isManager: Bool { currentUser.role == .manager }
    
    init(currentUser: StaffMember, staff: [StaffMember], shift: [Shift], openShifts: [OpenShift], swaps: [Swap], timeOff: [TimeOff]) {
        self.currentUser = currentUser
        self.staff = staff
        self.shift = shift
        self.openShifts = openShifts
        self.swaps = swaps
        self.timeOff = timeOff
    }
}
