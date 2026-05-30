#ifndef RULE_ENGINE_H
#define RULE_ENGINE_H

#include "ProxyEngine.h"
#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_PROCESS_NAME 256
#define MAX_TARGET_HOSTS 1024
#define MAX_TARGET_PORTS 256

// Rule structure
typedef struct ProxyRule {
    uint32_t rule_id;
    char process_name[MAX_PROCESS_NAME];
    char target_hosts[MAX_TARGET_HOSTS];
    char target_ports[MAX_TARGET_PORTS];
    RuleProtocol protocol;
    RuleAction action;
    ProxyInfo proxy;       // per-rule proxy (has_proxy=false means use global)
    bool enabled;
    struct ProxyRule* next;
} ProxyRule;

// Rule engine functions
void RuleEngine_Init(void);
void RuleEngine_Cleanup(void);

uint32_t RuleEngine_AddRule(const char* process, const char* hosts,
                            const char* ports, RuleProtocol proto, RuleAction action,
                            const ProxyInfo* proxy);
bool RuleEngine_RemoveRule(uint32_t rule_id);
bool RuleEngine_EnableRule(uint32_t rule_id, bool enable);
void RuleEngine_ClearRules(void);

// Match a connection against rules
// Returns the action to take (PROXY/DIRECT/BLOCK)
// If out_proxy is non-NULL, copies the matched rule's proxy info into it
RuleAction RuleEngine_Match(const char* process_name, uint32_t dest_ip,
                            uint16_t dest_port, bool is_tcp, ProxyInfo* out_proxy);

// Pattern matching helpers
bool RuleEngine_MatchProcessPattern(const char* pattern, const char* process_name);
bool RuleEngine_MatchIpPattern(const char* pattern, uint32_t ip);
bool RuleEngine_MatchPortPattern(const char* pattern, uint16_t port);

#ifdef __cplusplus
}
#endif

#endif // RULE_ENGINE_H
