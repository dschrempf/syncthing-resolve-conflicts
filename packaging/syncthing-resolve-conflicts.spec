Name:           syncthing-resolve-conflicts
Version:        0.0.0
Release:        1%{?dist}
Summary:        Interactively resolve Syncthing sync conflicts
License:        GPL-3.0-only
URL:            https://github.com/dschrempf/syncthing-resolve-conflicts
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       bash

%description
A Bash script that interactively resolves Syncthing sync conflicts,
inspired by pacdiff from Arch Linux. Supports locate, find, and fd as
search backends, and can discover watched folders from the Syncthing
configuration file.

%prep
%autosetup

%install
install -Dm755 %{name} %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/%{name}

%changelog
* Fri Jun 05 2026 Dominik Schrempf <dominik@well-typed.com> - 1.3.0-1
- Initial RPM packaging
