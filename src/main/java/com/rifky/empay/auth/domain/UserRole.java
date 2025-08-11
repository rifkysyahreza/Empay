package com.rifky.empay.auth.domain;

import jakarta.persistence.*;
import lombok.*;

import java.io.Serializable;
import java.util.UUID;

@Entity
@Table(name = "user_roles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@IdClass(UserRole.PK.class)
public class UserRole {
    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Id @Column(name = "role_id")
    private UUID roleId;

    @Data @NoArgsConstructor @AllArgsConstructor
    public static class PK implements Serializable {
        private UUID userId; private UUID roleId;
    }
}
