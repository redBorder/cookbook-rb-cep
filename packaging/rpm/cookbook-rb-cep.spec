Name: cookbook-rb-cep
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: Redborder-cep cookbook to install and configure it in redborder environments

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-rb-cep
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/var/chef/cookbooks/rb-cep
cp -f -r  resources/* %{buildroot}/var/chef/cookbooks/rb-cep/
chmod -R 0755 %{buildroot}/var/chef/cookbooks/rb-cep
install -D -m 0644 README.md %{buildroot}/var/chef/cookbooks/rb-cep/README.md

%pre

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload rbcep'
  ;;
esac

%files
%defattr(0755,root,root)
/var/chef/cookbooks/rb-cep
%defattr(0644,root,root)
/var/chef/cookbooks/rb-cep/README.md

%doc

%changelog
* Wed Feb 09 2022 Javier Rodríguez <javiercrg@redborder.com> - 1.0.0-1
- first spec version
