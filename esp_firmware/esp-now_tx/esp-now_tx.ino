#include <Arduino.h>
#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>

// ================= ПРОТОКОЛ SERIAL =================
#define CMD_CONFIG 0xC0  // Настройка: [0xC0] [CH] [MAC x6]
#define CMD_SEND   0xD0  // Отправка: [0xD0] [LEN] [DATA...]
#define CMD_RECV   0x52  // Прием:    [0x52] [LEN] [DATA...] (символ 'R')

uint8_t targetMac[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
bool peerAdded = false;

// Коллбэк: когда ESP32 получает данные из воздуха от дрона
void OnDataRecv(const uint8_t *mac, const uint8_t *incomingData, int len) {
    // Шлем в Flutter через Serial
    Serial.write(CMD_RECV);
    Serial.write((uint8_t)len);
    Serial.write(incomingData, len);
}

// Коллбэк отправки (необходим для API ESP-NOW)
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
    // Можно добавить отладку, если нужно
}

void addOrUpdatePeer(uint8_t channel) {
    // Сначала удаляем, если был
    if (esp_now_is_peer_exist(targetMac)) {
        esp_now_del_peer(targetMac);
    }

    // ВАЖНО: Сначала ставим канал WiFi
    esp_wifi_set_channel(channel, WIFI_SECOND_CHAN_NONE);

    // Теперь добавляем пира на этом канале
    esp_now_peer_info_t peerInfo = {};
    memcpy(peerInfo.peer_addr, targetMac, 6);
    peerInfo.channel = channel; // Канал должен совпадать с WiFi channel
    peerInfo.encrypt = false;

    if (esp_now_add_peer(&peerInfo) == ESP_OK) {
        peerAdded = true;
        Serial.println("Peer Configured OK"); 
    }
}

void setup() {
    Serial.begin(115200);
    
    // Инициализация WiFi в режиме станции
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();

    if (esp_now_init() != ESP_OK) {
        return;
    }
    
    esp_now_register_recv_cb(OnDataRecv);
    esp_now_register_send_cb(OnDataSent);
}

void loop() {
    if (Serial.available()) {
        uint8_t cmd = Serial.read();

        // 1. КОМАНДА КОНФИГУРАЦИИ (от Flutter)
        if (cmd == CMD_CONFIG) {
            // Ждем: Канал (1) + MAC (6) = 7 байт
            long timeout = millis();
            while(Serial.available() < 7 && (millis() - timeout < 100)) yield(); 
            
            if (Serial.available() >= 7) {
                uint8_t channel = Serial.read();
                Serial.readBytes(targetMac, 6);
                addOrUpdatePeer(channel);
            }
        } 
        // 2. КОМАНДА ОТПРАВКИ В ЭФИР (от Flutter)
        else if (cmd == CMD_SEND) {
            // Ждем: Длина (1)
            long timeout = millis();
            while(Serial.available() < 1 && (millis() - timeout < 100)) yield();
            
            if (Serial.available() >= 1) {
                uint8_t len = Serial.read();
                uint8_t buf[250];
                
                // Ждем сами данные
                timeout = millis();
                while(Serial.available() < len && (millis() - timeout < 100)) yield();
                
                if (Serial.available() >= len) {
                    Serial.readBytes(buf, len);
                    if (peerAdded) {
                        esp_now_send(targetMac, buf, len);
                    }
                }
            }
        }
    }
}
