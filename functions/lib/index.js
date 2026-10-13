"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.joinFamilyCircle = exports.createFamilyCircle = exports.onAlertResolved = exports.alertOnMissedCheckin = exports.triggerGracePeriodCheckHttp = exports.scheduledGracePeriodCheck = void 0;
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin SDK
if (!admin.apps.length) {
    admin.initializeApp();
}
__exportStar(require("./types"), exports);
var gracePeriodCheck_1 = require("./gracePeriodCheck");
Object.defineProperty(exports, "scheduledGracePeriodCheck", { enumerable: true, get: function () { return gracePeriodCheck_1.scheduledGracePeriodCheck; } });
Object.defineProperty(exports, "triggerGracePeriodCheckHttp", { enumerable: true, get: function () { return gracePeriodCheck_1.triggerGracePeriodCheckHttp; } });
var alertCreation_1 = require("./alertCreation");
Object.defineProperty(exports, "alertOnMissedCheckin", { enumerable: true, get: function () { return alertCreation_1.alertOnMissedCheckin; } });
var alertResolution_1 = require("./alertResolution");
Object.defineProperty(exports, "onAlertResolved", { enumerable: true, get: function () { return alertResolution_1.onAlertResolved; } });
var familyCircle_1 = require("./familyCircle");
Object.defineProperty(exports, "createFamilyCircle", { enumerable: true, get: function () { return familyCircle_1.createFamilyCircle; } });
Object.defineProperty(exports, "joinFamilyCircle", { enumerable: true, get: function () { return familyCircle_1.joinFamilyCircle; } });
//# sourceMappingURL=index.js.map