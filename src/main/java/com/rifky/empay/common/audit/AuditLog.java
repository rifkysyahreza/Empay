package com.rifky.empay.common.audit;

import com.vladmihalcea.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Type;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditLog {
    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "actor_user_id")
    private UUID actorUserId;

    private String action;
    private String entity;

    @Column(name = "entity_id")
    private UUID entityId;

    @Column(name = "created_at")
    private Instant createdAt;

    @Type(JsonType.class)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> metadata;
}
