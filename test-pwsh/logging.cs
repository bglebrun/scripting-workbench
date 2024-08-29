using System;
using Vanara.InteropServices;
using Vanara.PInvoke.AdvApi32;
using Vanara.PInvoke.Authz;

namespace Logging {
    public class Logger {
        public static void Write-SecurityLog(string status) {
            const int eventID = 4899;
            const string eventSource = "Get-ExampleScript";
            const string eventFile = "C:\\ExampleProgram.exe";

            using (new ElevPriv("SeAuditPrivilege")) {
                AUTHZ_SOURCE_SCHEMA_REGISTRATION authzSource = new AUTHZ_SOURCE_SCHEMA_REGISTRATION {
                    dwFlags = AUTHZ_SRC_SCHEMA_REG_FLAGS.AUTHZ_ALLOW_MULTIPLE_SOURCE_INSTANCES,
                    szEventSourceName = eventSource,
                    szEventMessageFile = eventFile,
                    szEventAccessStringsFile = eventFile
                };

                if (!AuthzInstallSecurityEventSource(0, authzSource)) {
                    throw new System.ComponentModel.Win32Exception();
                }

                if (!AuthzRegisterSecurityEventSource(0, eventSource, out var hEventProvider)) {
                    throw new System.ComponentModel.Win32Exception();
                }

                using SafeCoTaskMemString data = new(status);
                using SafeNativeArray<AUDIT_PARAM> mem = new(new[] {
                    new AUDIT_PARAM(AUDIT_PARAM_TYPE.APT_String, data),
                });

                AUDIT_PARAMS ap = new() { Count = (ushort)mem.Count, Parameters = mem };

                if (!AuthzReportSecurityEventFromParams(0, hEventProvider, eventID, PSID.NULL, ap)) {
                    throw new System.ComponentModel.Win32Exception();
                }

            }
        }
    }
}
