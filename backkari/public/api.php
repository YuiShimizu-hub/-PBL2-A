<?php
declare(strict_types=1);
require_once __DIR__ . '/../src/common/common.php';
require_once __DIR__ . '/../src/auth/auth.php';
require_once __DIR__ . '/../src/users/users.php';
require_once __DIR__ . '/../src/status/status.php';
require_once __DIR__ . '/../src/seats/seats.php';
require_once __DIR__ . '/../src/layout/layout.php';
require_once __DIR__ . '/../src/events/events.php';

try {
    $action = (string) ($_GET['action'] ?? '');
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET')
        checkCsrf();
    switch ($action) {
        case 'bootstrap':
            method('GET');
            success(['csrf' => csrfToken(), 'user' => currentUser()]);
        case 'login':
            handleLogin();
        case 'logout':
            handleLogout();
        case 'register':
            method('POST');
            fail('新規登録は管理者に依頼してください', 403, 'REGISTRATION_DISABLED');
        case 'admin-create-user':
            handleAdminCreateUser();
        case 'admin-verify':
            handleAdminVerify();
        case 'departments':
            handleDepartments();
        case 'me':
            handleMe();
        case 'update-me':
            handleUpdateMe();
        case 'change-password':
            handleChangePassword();
        case 'employees':
            handleEmployees();
        case 'overview':
            handleOverview();
        case 'favorite':
            handleFavorite();
        case 'status':
            handleStatus();
        case 'floors':
            handleFloors();
        case 'map':
            handleMap();
        case 'seat-checkin':
            handleSeatCheckin();
        case 'admin-layout':
            handleAdminLayout();
        case 'audit-logs':
            handleAuditLogs();
        default:
            fail('APIが見つかりません', 404, 'NOT_FOUND');
    }
} catch (ApiError $e) {
    respond(['ok' => false, 'error' => ['code' => $e->errorCode, 'message' => $e->getMessage()] + $e->details], $e->httpStatus);
} catch (PDOException $e) {
    error_log('DB error: ' . $e->getMessage());
    $code = (string) $e->getCode();
    $conflict = ($code === '23000');
    respond([
        'ok' => false,
        'error' => [
            'code' => $conflict ? 'DATA_CONFLICT' : 'DATABASE_ERROR',
            'message' => $conflict ? '登録内容が重複しています' : 'データベースでエラーが発生しました'
        ]
    ], $conflict ? 409 : 500);
} catch (Throwable $e) {
    error_log('API error: ' . $e->getMessage());
    respond(['ok' => false, 'error' => ['code' => 'SERVER_ERROR', 'message' => 'サーバーでエラーが発生しました']], 500);
}
