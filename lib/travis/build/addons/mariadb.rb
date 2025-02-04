require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Mariadb < Base
        SUPER_USER_SAFE = true

        MARIADB_GPG_KEY_OLD = '0xcbcb082a1bb943db'
        MARIADB_GPG_KEY_NEW = '0xf1656f24c74cd1d8'
        MARIADB_MIRROR  = 'nyc2.mirrors.digitalocean.com'

        def after_prepare
          sh.fold 'mariadb' do
            sh.echo "Installing MariaDB version #{mariadb_version}", ansi: :yellow
            sh.cmd "service mysql stop", sudo: true
            sh.if '"$TRAVIS_DIST" == precise || "$TRAVIS_DIST" == trusty' do
              sh.cmd "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 #{MARIADB_GPG_KEY_OLD}", sudo: true
            end
            sh.else do
              sh.cmd "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 #{MARIADB_GPG_KEY_NEW}", sudo: true
            end
            sh.cmd 'add-apt-repository --yes "deb http://%p/mariadb/repo/%p/ubuntu $TRAVIS_DIST main"' % [MARIADB_MIRROR, mariadb_version], sudo: true
            sh.cmd 'travis_apt_get_update', retry: true, echo: true
            sh.cmd "PACKAGES='mariadb-server-#{mariadb_version}'", echo: true
            sh.cmd "if [[ $(lsb_release -cs) = 'precise' ]]; then PACKAGES=\"${PACKAGES} libmariadbclient-dev\"; fi", echo: true
            sh.if '"$TRAVIS_DIST" != precise && "$TRAVIS_DIST" != trusty' do
              sh.cmd 'rm -rf /var/lib/mysql', sudo: true, echo: false, timing: false
            end
            sh.cmd "apt-get install -y -o Debug::pkgProblemResolver=yes -o Dpkg::Options::='--force-confnew' $PACKAGES", sudo: true, echo: true, timing: true
            sh.echo "Starting MariaDB v#{mariadb_version}", ansi: :yellow
            sh.if '"$TRAVIS_INIT" == upstart' do
              sh.cmd "service mysql start", sudo: true, assert: false, echo: true, timing: true
            end
            sh.else do
              sh.cmd "systemctl start mysql", sudo: true, assert: false, echo: true, timing: true
            end
            sh.export 'TRAVIS_MARIADB_VERSION', mariadb_version, echo: false
            sh.cmd "mysql --version", assert: false, echo: true
          end
        end

        private
        def mariadb_version
          config.to_s.shellescape
        end
      end
    end
  end
end
