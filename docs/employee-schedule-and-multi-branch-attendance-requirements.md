# Employee Scheduling, Compensation, and Multi-Branch Attendance

**Status:** Implemented locally. Production migration, deployment, and organization backfill are pending.

This file is the working specification for employee details, schedules, weekly days off, salary history, and multi-branch attendance. Add further requirements here for the next implementation batch.

## Confirmed Requirements

### Employee details

- Employee details have three tabs: **Overview**, **Schedule & Shifts**, and **Salary**.
- Keep the employee creation form and its current fields. Add a weekly day-off selector to its schedule section.
- After creation, edit schedule and salary from their own tabs. Saving either must not update unrelated employee details.
- Apply existing employee-management permissions. Organization Admins manage employees across their organization. Branch Managers manage employees assigned to their active branch. A schedule or salary change made by a Branch Manager applies to the employee across all assigned branches.

### Schedule and weekly day off

- The shift belongs to the employee, not a branch. Its start time, end time, and daily work target apply at every assigned branch.
- The existing **Daily Work Hours** field remains. Preserve its current synchronization with the shift window: changing daily hours adjusts the shift end time, and changing the shift end time recalculates daily hours.
- Each employee has one recurring weekday off per week. The weekday is employee-specific and may change over time.
- Store the weekly day off in the employee’s effective-dated schedule history. A schedule change, including a day-off change, takes effect today or on a future date. Past effective dates are not allowed.
- Schedule periods for the same employee must not overlap, regardless of branch.
- Existing employees receive Sunday as their weekly day off during migration. New employees choose a weekday in the creation form.
- Do not include a public or organization-wide holiday calendar in this scope.

### Salary history

- The Salary tab shows current salary information and prior salary values.
- Preserve the existing monthly salary/CTC field. Additional pay types are not included in this scope.
- Salary changes are effective today or in the future. Backdated changes are not allowed.

### Payslips and monthly pay reports

- Add a Payslips page with monthly pay details and reports for the selected calendar month.
- Branch Managers can view their own payslip and payslips for employees assigned to their active branch. Organization Admins can view their own payslip and all employee payslips in their organization.
- Provide a monthly report and export for all employees within the viewer’s authorized scope. Use the same scope for page results and exports.
- An organization setting selects the pay calculation basis. Default to hours-based calculation. The alternate workday-based mode pays a full scheduled workday share when an employee has any valid attendance punch that day, even if the employee worked only one hour.
- Hours-based gross pay is monthly salary multiplied by payable hours divided by scheduled hours in the calendar month. Exclude weekly days off from scheduled hours.
- Workday-based gross pay is monthly salary multiplied by payable workdays divided by scheduled workdays in the calendar month. Exclude weekly days off from scheduled workdays. Count at most one payable workday per employee per scheduled day, regardless of the number of branch sessions.
- Approved leave is unpaid and contributes no payable hours or workdays.
- Apply each salary rate only over the dates when that salary version is effective within the selected month.
- Add an organization overtime setting, disabled by default. When enabled, pay actual work hours beyond the scheduled daily hours at the employee’s regular hourly rate. When disabled, hours above the scheduled daily target do not increase pay.
- Payslips and monthly reports show gross calculated pay. Tax, statutory deductions, benefits, payroll approval, and payment disbursement are outside this scope.

### Attendance across branches

- An employee can check in and out at Branch A, then start and finish a new session at Branch B on the same business day. Any number of sequential sessions is allowed.
- The employee chooses an active assigned branch when starting each session. Check-out is tied to the branch of the open session.
- A new session cannot start while another session is open. Only one session may be open at a time.
- Existing GPS, branch geofence, selfie, and break requirements continue to apply to each punch. A break must end before the session is checked out.
- Worked time accumulates across the day’s sessions, less recorded breaks. Time between sessions is not worked time.
- Show one employee/day attendance summary with the sessions and branch history available from it. Daily headcounts count an employee once, even when they worked at multiple branches.
- Organization Admins can review organization-wide session history. Branch Managers can see only sessions within their authorized branch scope. Employees can see their own attendance history.
- When an employee’s effective schedule marks the day as their weekly day off, block attendance punches. Do not count the employee as scheduled or absent for that day.
- Branch Manager self-attendance follows the existing organization setting that enables or disables it.

## Implementation Status and Rollout

- Migration 010 adds effective-dated schedule and compensation history in PostgreSQL. Authorized Cloud Function operations read, save, and backfill these records.
- Employee details now separate Overview, Schedule & Shifts, and Salary. Initial schedule and salary remain in employee creation; later history edits save independently.
- Employee self-service can select an assigned active branch for each new attendance session. Each session retains its own branch, and checkout is tied to the open session.
- Attendance views group sessions into one employee/day summary. Session history and review actions remain available from the summary, and employee history spans all branches.
- Effective weekly days off block self-service and group attendance punches. Organization pay settings choose hours or workdays and default overtime to off. Payslips and scoped exports are available in the app.
- Local tests and analysis validate the implementation. Before release, apply migration 010, deploy Functions/rules/indexes and the app, then run the backfill for each organization. Production migration and backfill have not been run.

## Implementation Details

### Employee schedule and compensation storage

- Add a PostgreSQL employee schedule history table keyed by organization member. Each version stores effective dates, shift start/end, daily work hours, and one weekday-off value.
- Add a separate PostgreSQL compensation history table keyed by organization member. Each version stores the existing salary/CTC value and its effective dates.
- Use non-overlapping half-open effective date ranges per employee: a version applies from its effective date through, but not including, its end date. Index employee ID and effective dates so the applicable schedule and compensation are found without a full-table scan.
- Route reads and writes through authorized Cloud Functions and the existing SQL data-access layer. Organization Admin access is organization-scoped. Branch Manager access is limited to employees assigned to their active branch. Do not expose salary in manager-readable profile projections.
- New employee provisioning writes the initial schedule and compensation versions. Post-creation schedule and salary changes use separate tab actions and backend operations.
- Backfill existing employees’ current shift and daily work hours from Firestore, and seed Sunday as their weekly day off. Backfill each available current salary value from the private Firestore profile. Use the Asia/Kolkata business date at cutover as the first effective date because prior history is unavailable.
- After validating the backfill and switching reads and writes, stop treating Firestore schedule and salary fields as authoritative. Remove legacy schedule or salary fields only when the corresponding SQL history was imported successfully. Keep Aadhaar data in its existing private storage.

### Payslip and payroll calculation

- Add organization-level settings for calculation basis and overtime. Persist calculation basis as hours-based or workday-based, defaulting to hours-based. Persist overtime as disabled by default.
- For hours-based pay, calculate eligible hours from all attendance sessions in the month, across branches, subtracting recorded breaks. Approved leave contributes zero payable hours. Scheduled hours include the effective shift for each scheduled workday in the month and exclude weekly days off.
- For workday-based pay, a valid attendance punch on a scheduled workday earns one workday share of the effective monthly salary. Multiple sessions on the same date still count as one workday. Approved leave with no attendance punch earns no workday share.
- For both modes, calculate the monthly amount as a weighted sum across salary effective-date segments. For each segment, multiply that segment’s monthly salary by the eligible hours or workdays in the segment, divided by the scheduled hours or workdays for the full calendar month.
- Determine overtime per scheduled day as actual worked time beyond that day’s scheduled shift duration. If enabled, add those excess hours at the regular hourly rate derived from the effective monthly salary and scheduled monthly hours. If disabled, exclude excess hours from payable hours and do not add overtime pay.
- Show the selected pay basis and an auditable breakdown of salary rate, scheduled hours or days, payable hours or days, unpaid leave impact, overtime hours and pay, and gross pay.
- Generate an individual payslip as PDF and the monthly scoped payroll report as XLSX. Do not trigger salary payments or create a payroll approval workflow.
- Enforce payslip reads and exports server-side. A Branch Manager can access their own records and employees assigned to their active branch; an Organization Admin can access their own records and all organization employees.

### Attendance session storage and access

- Store each self-service work session as a separate attendance entry with its own employee, organization, branch, work date, check-in/out times, breaks, selfie paths, and location validation data.
- Use trusted server-side transaction logic to enforce one open session per employee and business date, bind check-out to the open session’s branch, and reject punches on a weekly day off.
- Preserve existing daily attendance entries as historical single-session records. New sessions use unique IDs so an employee can create more than one entry on a date.
- Group entries by employee and business date for daily views. Deduplicate employee IDs for headcounts. Branch-scoped reads must return only sessions in the caller’s authorized branch scope.
- Apply weekly-day-off validation to employee self-service punches and manager-recorded group attendance. Do not provide an override to punch on the weekly day off.
- Show a **Weekly Off** state in the employee attendance experience instead of a check-in action on that day.

### User interface

- The employee detail page uses Overview, Schedule & Shifts, and Salary tabs.
- Keep initial schedule and salary entry in the employee creation form and add the weekly-day-off selection there.
- Remove schedule and salary editing from the general employee edit flow after account creation. Each dedicated tab has its own view and save action.
- The Schedule & Shifts tab shows the current and historical shift window, daily work hours, and weekly day off.
- The Salary tab shows the current and historical salary/CTC values, ordered by effective date.
- The Payslips page supports a calendar-month selector, scoped employee pay details, individual PDF payslips, and an XLSX export of all employees in the viewer’s authorized scope.
- The employee attendance home lets the employee choose an assigned active branch before each new check-in. During an open session, it shows the session branch and offers check-out for that session.

## Acceptance Checklist

- [x] An employee can select any active assigned branch for each new session.
- [x] An employee can check out at one branch and start another session at a different assigned branch on the same business day.
- [x] Check-out uses the open session’s branch; inactive or unassigned branches are rejected.
- [x] A second session is rejected while another session or break is open.
- [x] GPS, geofence, selfie, and existing role rules apply to every relevant punch.
- [x] Weekly-day-off punches are rejected, and scheduled weekly days off are excluded from absence counts.
- [x] Existing employees receive Sunday during migration; newly created employees can choose their weekly day off.
- [x] Branch and organization attendance views show correctly scoped session history and count employees once per day.
- [x] Employee home displays the active session branch and accumulates worked time across sessions.
- [x] The applicable shift and weekly day off are found by employee and business date without scanning schedule history.
- [x] Schedule and salary changes preserve history, use today/future effective dates, and reject overlapping periods.
- [x] Hours-based pay is the default organization setting; workday-based pay is available as an alternative.
- [x] Workday-based pay counts one full scheduled day for any valid punch, while hours-based pay uses accumulated session time less breaks.
- [x] Weekly days off and approved unpaid leave do not create payable time or days.
- [x] Salary effective-date changes within a month are reflected in the corresponding portions of the calculation.
- [x] Overtime is disabled by default and adds hours beyond the scheduled daily shift at the regular hourly rate only when enabled.
- [x] Branch Managers and Organization Admins can view their own payslips and employee payslips within their authorized scope.
- [x] Monthly XLSX exports contain every employee in scope for the selected calendar month; individual payslips can be exported as PDF.
- [x] The employee creation form retains schedule and salary entry and adds weekly-day-off selection.
- [x] Post-creation schedule and salary edits are isolated from general employee details.
- [ ] Backfilled shift and salary values match existing records, and all existing employees have Sunday seeded as their weekly day off.

The checked items are implemented and locally validated. The final item remains
open until the migration and backfill have been run and their real data has
been checked in the target environment.
