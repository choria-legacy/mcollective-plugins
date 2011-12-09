Name:		@NAME@
Version:	@VERSION@
Release:	@RELEASE@%{?dist}
Summary:	A dummy package to test bigbang.

Group:		unknown
License:	unknown
URL:		unknown
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description

%prep

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/share/@NAME@
touch $RPM_BUILD_ROOT/usr/share/@NAME@/README

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
/usr/share/@NAME@/README
%doc

%changelog
