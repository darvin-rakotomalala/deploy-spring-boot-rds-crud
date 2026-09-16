package com.ce.mapper;

import com.ce.model.domain.Note;
import com.ce.model.dto.NoteDTO;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor"
)
@Component
public class NoteMapperImpl implements NoteMapper {

    @Override
    public Note toDO(NoteDTO dto) {
        if ( dto == null ) {
            return null;
        }

        Note note = new Note();

        if ( dto.getCreatedAt() != null ) {
            note.setCreatedAt( Date.from( dto.getCreatedAt() ) );
        }
        if ( dto.getUpdatedAt() != null ) {
            note.setUpdatedAt( Date.from( dto.getUpdatedAt() ) );
        }
        note.setId( dto.getId() );
        note.setTitle( dto.getTitle() );
        note.setContent( dto.getContent() );

        return note;
    }

    @Override
    public NoteDTO toDTO(Note entity) {
        if ( entity == null ) {
            return null;
        }

        NoteDTO noteDTO = new NoteDTO();

        noteDTO.setId( entity.getId() );
        noteDTO.setTitle( entity.getTitle() );
        noteDTO.setContent( entity.getContent() );
        if ( entity.getCreatedAt() != null ) {
            noteDTO.setCreatedAt( entity.getCreatedAt().toInstant() );
        }
        if ( entity.getUpdatedAt() != null ) {
            noteDTO.setUpdatedAt( entity.getUpdatedAt().toInstant() );
        }

        return noteDTO;
    }

    @Override
    public List<Note> toDO(List<NoteDTO> dtoList) {
        if ( dtoList == null ) {
            return null;
        }

        List<Note> list = new ArrayList<Note>( dtoList.size() );
        for ( NoteDTO noteDTO : dtoList ) {
            list.add( toDO( noteDTO ) );
        }

        return list;
    }

    @Override
    public List<NoteDTO> toDTO(List<Note> entityList) {
        if ( entityList == null ) {
            return null;
        }

        List<NoteDTO> list = new ArrayList<NoteDTO>( entityList.size() );
        for ( Note note : entityList ) {
            list.add( toDTO( note ) );
        }

        return list;
    }
}
