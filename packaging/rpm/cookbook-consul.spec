Name: cookbook-consul
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: Hashicorp Consul cookbook to install and configure it in redborder environments

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-consul
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/var/chef/cookbooks/consul
cp -f -r  resources/* %{buildroot}/var/chef/cookbooks/consul/
chmod -R 0755 %{buildroot}/var/chef/cookbooks/consul
install -D -m 0644 README.md %{buildroot}/var/chef/cookbooks/consul/README.md

%pre

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload consul'
  ;;
esac

%files
%defattr(0755,root,root)
/var/chef/cookbooks/consul
%defattr(0644,root,root)
/var/chef/cookbooks/consul/README.md
%doc

%changelog
* Fri Jan 07 2022 David Vanhoucke <dvanhoucke@redborder.com> - 1.0.5-1
- add /etc/network under control of the chef
* Tue Oct 18 2016 Alberto Rodríguez <arodriguez@redborder.com> - 1.0.0-1
- first spec version
