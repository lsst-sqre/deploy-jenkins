# deep merge w/ merge_hash_arrays is incapable of properly merging multiple
# `- credentails` array of hash elements under:
#
# credentials:
#   system:
#     domainCredentials:
#       [- credentials:]
#
# as it converts `basicSSHUserPrivateKey` array elements to encapsulated in a
# hash IF they are not in the base hash but lower down in the hierachy. Yes,
# this seems crazy, having nested hashes does not appear to be the triggering
# condition nor not having a similar value to shadow from lower in the
# hierachy.
$casc = lookup({
  name       => 'jenkinsx::casc',
  value_type => Hash[String, Any],
  merge      => {
    strategy          => 'deep',
    merge_hash_arrays => false,
  },
})

# helm jenkins chart values
$master = lookup({
  name       => 'jenkinsx::master',
  value_type => Hash[String, Any],
  merge      => {
    strategy          => 'deep',
    merge_hash_arrays => false,
  },
})

if $casc {
  if $casc['credentials'] and
    $casc['credentials']['system'] and
    $casc['credentials']['system']['domainCredentials'] {
    $dom_creds = $casc['credentials']['system']['domainCredentials']
    $merged_creds = $dom_creds.reduce([]) |Array $result, Hash $value| {
      $result + $value['credentials']
    }
    $real_casc = $casc + {
      credentials => {
        system => {
          domainCredentials => [ credentials => $merged_creds ],
        },
      }
    }
  } else {
    $real_casc = $casc
  }

  $real_master = deep_merge($master, {
    'master' => {
      'JCasC' => {
        'configScripts' => { '01-casc' => inline_template("<%- require 'yaml'-%><%= YAML.dump(@real_casc) %>") }
      }
    }
  })

  # debug -- WILL PRINT SECRETS
  notice('merged config:')
  notice(inline_template("<%- require 'yaml'-%><%= YAML.dump(@real_master) %>"))

  file { "${::pwd}/jenkins.yaml":
    content => inline_template("<%- require 'yaml'-%><%= YAML.dump(@real_master) %>"),
  }
}
