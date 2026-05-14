/// The supported app roles.
///
/// These values are intentionally aligned with the architecture plan so they can
/// later map cleanly to role rows in Supabase.
enum AppUserRole {
  customer,
  stylist,
  admin,
  franchisee,
  corporateAdmin,
}

/// Parses database role values into the app enum.
extension AppUserRoleParsing on AppUserRole {
  static AppUserRole? fromDatabase(String? value) {
    switch (value) {
      case 'customer':
        return AppUserRole.customer;
      case 'stylist':
        return AppUserRole.stylist;
      case 'admin':
        return AppUserRole.admin;
      case 'franchisee':
        return AppUserRole.franchisee;
      case 'corporate_admin':
        return AppUserRole.corporateAdmin;
      default:
        return null;
    }
  }
}

/// Helpful extensions for route decisions and readable UI labels.
extension AppUserRoleX on AppUserRole {
  String get label {
    switch (this) {
      case AppUserRole.customer:
        return 'Customer';
      case AppUserRole.stylist:
        return 'Stylist';
      case AppUserRole.admin:
        return 'Admin';
      case AppUserRole.franchisee:
        return 'Franchisee';
      case AppUserRole.corporateAdmin:
        return 'Corporate Admin';
    }
  }

  bool get isSupportedInApp {
    return this == AppUserRole.customer ||
        this == AppUserRole.stylist ||
        this == AppUserRole.admin;
  }

  String? get homeLocation {
    switch (this) {
      case AppUserRole.customer:
        return '/customer/home';
      case AppUserRole.stylist:
        return '/stylist/home';
      case AppUserRole.admin:
        return '/admin/home';
      case AppUserRole.franchisee:
      case AppUserRole.corporateAdmin:
        return null;
    }
  }
}