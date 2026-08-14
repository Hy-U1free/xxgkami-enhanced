<template>
  <div class="login-container admin-theme">
    <div class="login-card admin-card">
      <div class="login-header">
        <div class="brand-logo">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="logo-icon admin-icon">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
            <polyline points="9 12 11 14 15 10" stroke-width="2"></polyline>
          </svg>
        </div>
        <h2>管理员控制台</h2>
        <p>仅限授权管理员登录</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label for="admin-username">管理员账号</label>
          <input
            id="admin-username"
            type="text"
            v-model="loginForm.username"
            placeholder="请输入管理员账号"
            required
            :disabled="loading"
          />
        </div>

        <div class="form-group">
          <label for="admin-password">密码</label>
          <div class="password-input">
            <input
              id="admin-password"
              :type="showPassword ? 'text' : 'password'"
              v-model="loginForm.password"
              placeholder="请输入密码"
              required
              :disabled="loading"
            />
            <button
              type="button"
              class="password-toggle"
              @click="showPassword = !showPassword"
              :disabled="loading"
            >
              <svg v-if="showPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                <line x1="1" y1="1" x2="23" y2="23"></line>
              </svg>
              <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
            </button>
          </div>
        </div>

        <div class="form-actions">
          <button
            type="submit"
            class="login-button"
            :disabled="loading || !loginForm.username || !loginForm.password"
          >
            {{ loading ? '登录中...' : '登录' }}
          </button>
        </div>
      </form>

      <div v-if="errorMessage" class="message error-message">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="12" y1="8" x2="12" y2="12"></line>
          <line x1="12" y1="16" x2="12.01" y2="16"></line>
        </svg>
        {{ errorMessage }}
      </div>

      <div v-if="successMessage" class="message success-message">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
          <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
        {{ successMessage }}
      </div>
    </div>

    <!-- TOTP 双重验证弹窗 -->
    <div v-if="showTotpInput" class="modal-overlay">
      <div class="modal-content" style="max-width: 400px;">
        <div class="modal-header">
          <h3>双重验证 (2FA)</h3>
          <button class="close-button" @click="showTotpInput = false">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>
        <div class="modal-body">
          <p class="totp-instruction">请输入您的 Authenticator 应用生成的 6 位验证码</p>
          <form @submit.prevent="handleTotpLogin" class="totp-form">
            <div class="form-group">
              <label>验证码</label>
              <input
                ref="totpInputRef"
                type="text"
                v-model="loginForm.totpCode"
                required
                placeholder="000000"
                maxlength="6"
                pattern="\d{6}"
                class="totp-input"
                autocomplete="one-time-code"
              >
            </div>

            <div v-if="errorMessage" class="message error-message">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
              </svg>
              {{ errorMessage }}
            </div>

            <button type="submit" class="login-button" :disabled="loading">
              {{ loading ? '验证中...' : '验证' }}
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, nextTick, watch } from 'vue'
import { authApi } from '../services/api.js'

const emit = defineEmits(['login-success'])

const showPassword = ref(false)
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const showTotpInput = ref(false)
const totpInputRef = ref(null)

const loginForm = reactive({
  username: '',
  password: '',
  totpCode: ''
})

// 自动消失的消息
const autoDismiss = (messageRef) => {
  watch(messageRef, (newVal) => {
    if (newVal) {
      setTimeout(() => {
        messageRef.value = ''
      }, 5000)
    }
  })
}

[errorMessage, successMessage].forEach(autoDismiss)

// 处理登录
const handleLogin = async () => {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const response = await authApi.adminLogin({
      username: loginForm.username,
      password: loginForm.password
    })

    if (response.success) {
      // 检查是否需要 TOTP 验证
      if (response.data.needTotp) {
        showTotpInput.value = true
        loading.value = false
        await nextTick()
        totpInputRef.value?.focus()
        return
      }

      // 登录成功
      successMessage.value = '登录成功！'

      // 保存登录信息
      localStorage.setItem('token', response.data.token)
      localStorage.setItem('refreshToken', response.data.refreshToken)
      localStorage.setItem('userInfo', JSON.stringify(response.data.userInfo))
      localStorage.setItem('isLoggedIn', 'true')

      setTimeout(() => {
        emit('login-success', response.data)
      }, 500)
    } else {
      errorMessage.value = response.message || '登录失败，请检查用户名和密码'
    }
  } catch (error) {
    console.error('登录失败:', error)
    errorMessage.value = '登录失败: ' + (error.message || '网络错误')
  } finally {
    loading.value = false
  }
}

// 处理 TOTP 登录
const handleTotpLogin = async () => {
  if (!loginForm.totpCode || loginForm.totpCode.length !== 6) {
    errorMessage.value = '请输入6位验证码'
    return
  }

  loading.value = true
  errorMessage.value = ''

  try {
    const response = await authApi.adminLogin({
      username: loginForm.username,
      password: loginForm.password,
      totpCode: loginForm.totpCode
    })

    if (response.success) {
      successMessage.value = '登录成功！'

      // 保存登录信息
      localStorage.setItem('token', response.data.token)
      localStorage.setItem('refreshToken', response.data.refreshToken)
      localStorage.setItem('userInfo', JSON.stringify(response.data.userInfo))
      localStorage.setItem('isLoggedIn', 'true')

      showTotpInput.value = false

      setTimeout(() => {
        emit('login-success', response.data)
      }, 500)
    } else {
      errorMessage.value = response.message || 'TOTP验证失败'
    }
  } catch (error) {
    console.error('TOTP验证失败:', error)
    errorMessage.value = 'TOTP验证失败: ' + (error.message || '网络错误')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  box-sizing: border-box;
}

.login-container.admin-theme {
  background: linear-gradient(135deg, #1e1e2f 0%, #2d1b3d 50%, #1a1a2e 100%);
}

.login-card {
  background: white;
  border: none;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15), 0 4px 20px rgba(0, 0, 0, 0.08);
  padding: 2.5rem;
  width: 100%;
  max-width: 420px;
}

.login-card.admin-card {
  background: #ffffff;
  border-top: 4px solid #dc2626;
  border-radius: 12px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.35), 0 4px 20px rgba(220, 38, 38, 0.1);
}

.login-header {
  text-align: center;
  margin-bottom: 2rem;
}

.brand-logo {
  display: flex;
  justify-content: center;
  margin-bottom: 1rem;
}

.logo-icon {
  width: 48px;
  height: 48px;
}

.logo-icon.admin-icon {
  width: 52px;
  height: 52px;
  color: #dc2626;
}

.admin-card .login-header h2 {
  color: #1e1e2f;
  margin: 0 0 0.5rem 0;
  font-size: 1.5rem;
  font-weight: 700;
  letter-spacing: -0.025em;
}

.admin-card .login-header p {
  color: #9ca3af;
  margin: 0;
  font-size: 0.8rem;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.login-form {
  margin-top: 1.5rem;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #374151;
  font-size: 0.875rem;
}

.form-group input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 0.95rem;
  transition: all 0.2s;
  box-sizing: border-box;
}

.form-group input:focus {
  outline: none;
  border-color: #dc2626;
  box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.1);
}

.form-group input:disabled {
  background: #f3f4f6;
  cursor: not-allowed;
}

.password-input {
  position: relative;
  display: flex;
  align-items: center;
}

.password-input input {
  flex: 1;
  padding-right: 2.75rem;
}

.password-toggle {
  position: absolute;
  right: 0.75rem;
  background: none;
  border: none;
  cursor: pointer;
  color: #6b7280;
  padding: 0.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.2s;
}

.password-toggle:hover:not(:disabled) {
  background: #f3f4f6;
  color: #111827;
}

.password-toggle:disabled {
  cursor: not-allowed;
  opacity: 0.5;
}

.password-toggle svg {
  width: 18px;
  height: 18px;
}

.form-actions {
  margin-top: 1.5rem;
}

.login-button {
  width: 100%;
  padding: 0.875rem;
  border: none;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  background: linear-gradient(135deg, #dc2626, #b91c1c);
  color: white;
}

.login-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #b91c1c, #991b1b);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(220, 38, 38, 0.3);
}

.login-button:disabled {
  background: #e5e7eb;
  color: #9ca3af;
  cursor: not-allowed;
  transform: none;
}

.message {
  padding: 0.75rem;
  border-radius: 4px;
  margin-top: 1.5rem;
  font-size: 0.875rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.message svg {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
}

.error-message {
  background: #fef2f2;
  color: #b91c1c;
  border: 1px solid #fecaca;
}

.success-message {
  background: #ecfdf5;
  color: #047857;
  border: 1px solid #a7f3d0;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.modal-content {
  background: white;
  border-radius: 4px;
  width: 100%;
  max-width: 400px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}

.modal-header {
  padding: 1rem 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e5e7eb;
}

.modal-header h3 {
  margin: 0;
  color: #111827;
  font-size: 1.1rem;
  font-weight: 600;
}

.close-button {
  background: none;
  border: none;
  cursor: pointer;
  color: #6b7280;
  padding: 0.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
}

.close-button:hover {
  background: #f3f4f6;
  color: #111827;
}

.close-button svg {
  width: 20px;
  height: 20px;
}

.modal-body {
  padding: 1.5rem;
}

.totp-instruction {
  margin: 0 0 1rem 0;
  color: #4b5563;
  line-height: 1.5;
  font-size: 0.9rem;
}

.totp-form .form-group {
  margin-bottom: 1rem;
}

.totp-input {
  text-align: center;
  font-size: 1.5rem;
  letter-spacing: 0.5rem;
  font-weight: 600;
}

@media (max-width: 480px) {
  .login-card {
    padding: 1.5rem;
  }
}
</style>
